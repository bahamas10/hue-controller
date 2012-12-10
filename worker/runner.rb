module Worker
  class Runner
    attr_reader :job_states

    def initialize(options)
      if File.exists?("./config/job_states.yml")
        @job_states = YAML::load_file("./config/job_states.yml")
      else
        @job_states = {}
      end

      load_jobs

      @running = true
      @processor = Processor.new(self, options)
    end

    def start
      puts "* Starting..."

      while @running do
        load_jobs

        job_status = nil
        @jobs.each do |job|
          # Not time to run this yet
          if @job_states[job[:id]][:run_at] > Time.now.utc or @job_states[job[:id]][:active]
            next
          end

          job_status = @processor.run(job)
          break
        end

        break unless @running

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

      @running = false
      @processor.stop

      unless @job_states.empty?
        @job_states.each {|k, v| v.delete(:active)}

        File.open("./config/job_states.yml", "w+") do |f|
          f.write(@job_states.to_yaml)
        end
      end
    end

    private
    # Check if we need to load the initial state on something
    def setup_states
      @jobs.each do |job|
        @job_states[job[:id]] ||= {:run_at => Time.now.utc, :runs_left => job[:times_to_run]}
        @job_states[job[:id]][:found] = true
      end

      # Prune any states we couldn't find
      @job_states.delete_if do |id, state|
        !state.delete(:found)
      end
    end

    # Load job config file
    def load_jobs
      # Check if the mod time on the config file changed
      if @jobs
        mtime = File.mtime("./config/jobs.yml")
        return if @jobs_mtime == mtime
        @jobs_mtime = mtime
      else
        @jobs_mtime = File.mtime("./config/jobs.yml")
      end

      puts @jobs ? "* Reloaded jobs" : "* Loaded jobs"
      @jobs = YAML::load_file("./config/jobs.yml")

      setup_states
    end

    # Remove a job
    def remove_job(id)
      # Do one last check to see if it changed before we remove the job
      load_jobs

      @job_states.delete(id)
      @jobs.delete_if do |job|
        puts "* Removing job #{job[:name]} (id #{job[:id]})"

        job[:id] == id
      end

      @jobs_mtime = File.mtime("./config/jobs.yml")
      File.open("./config/jobs.yml") {|f| f.write(@jobs.to_yaml)}
    end
  end
end