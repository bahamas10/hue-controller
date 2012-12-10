module Worker
  class Runner
    attr_reader :job_states, :communicator

    def initialize(options)
      if File.exists?("./config/job_states.yml")
        @job_states = YAML::load_file("./config/job_states.yml") || {}
      else
        @job_states = {}
      end

      @mtimes = {}
      @processor = Processor.new(self, options)
      @communicator = HubCommunicator.new
      @job_mutex = Mutex.new
    end

    def start
      puts "* Starting..."

      until @stopped do
        # Check for jobs change
        load_if_changed(:jobs, "./config/jobs.yml")

        # Check for config change
        load_if_changed(:hub_config, "./config/config.yml")

        # Try and find a job
        active_job = nil
        @job_mutex.synchronize do
          @jobs.each do |job|
            # Not time to run this yet
            if @job_states[job[:id]][:run_at] > Time.now.utc or @job_states[job[:id]][:active]
              next
            end

            active_job = job
            break
          end
        end

        if active_job
          job_status = @processor.run(active_job)
        end

        break if @stopped

        # Can't queue anymore jobs, give it some time
        if job_status == :capacity
          puts "* At thread capacity, "
          sleep 5

        # Nothing found, sleep for a while
        elsif @jobs.empty?
          puts "* No jobs found, sleeping for 10 seconds"
          sleep 10
        end
      end
    end

    def stop
      puts "* Stopping..."

      @stopped = false
      @processor.stop

      # Don't save any active states
      @job_states.each {|k, v| v.delete(:active)}

      flush_states
    end

    # Remove a job
    def remove_job(id)
      # Do one last check to see if it changed before we remove the job
      load_if_changed(:jobs, "./config/jobs.yml")

      @job_mutex.synchronize do
        @jobs.delete_if do |job|
          if job[:id] == id
            puts "* Removing job #{job[:name]} (id #{job[:id]})"
            true
          else
            false
          end
        end

        @job_states.delete(id)
      end

      @mtimes[:jobs] = File.mtime("./config/jobs.yml")
      File.open("./config/jobs.yml", "w+") {|f| f.write(@jobs.to_yaml)}
    end

    private
    def flush_states
      if @jobs.empty?
        @job_states = {}
      else
        # Prune anything we need to
        active_jobs = {}
        @jobs.each {|j| active_jobs[j[:id]] = true}
        @job_states.delete_if {|id, v| !active_jobs[id]}

        # Make sure we don't store the active flag
        @job_states.each_value {|v| v.delete(:active)}
      end

      # Flush to disk
      File.open("./config/job_states.yml", "w+") do |f|
        f.write(@job_states.to_yaml)
      end
    end

    # Check if we need to load the initial state on something
    def setup_states
      @jobs.each do |job|
        @job_states[job[:id]] ||= {:run_at => Time.now.utc, :runs_left => job[:times_to_run]}
        @job_states[job[:id]][:found] = true
      end
    end

    def load_if_changed(type, path)
      mtime = File.mtime(path)
      if @mtimes[type] == mtime
        return
      end

      data = YAML::load_file(path)

      if type == :hub_config
        @communicator.config = {:apikey => data[:apikey], :ip => data[:ip]}
      else
        @job_mutex.synchronize do
          @jobs = data || []

          setup_states
        end
      end

      puts @mtimes[type] ? "* Reloaded #{path}" : "* Loaded #{path}"
      @mtimes[type] = mtime
    end
  end
end