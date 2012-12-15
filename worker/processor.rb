module Worker
  class Processor
    attr_reader :boss, :state_mutex

    def initialize(boss, options)
      @boss = boss

      @threads = []
      @max_threads = options[:cores]
      @state_mutex = Mutex.new
    end

    def run(job)
      return :capacity unless thread_available?
      puts "** Running job #{job[:name]} (#{job[:id]})"

      @state_mutex.synchronize do
        @boss.job_states[job[:id]][:active] = true
      end

      @threads << Thread.new(self, job) do |processor, data|
        begin
          klass = Worker::Job.const_get(data[:type].capitalize)
          job_instance = klass.new(processor.state_mutex, processor.boss.job_states[data[:id]], job)

          states = job_instance.run
          if states
            @boss.communicator.apply_states(states)
          end

          processor.job_finished(job_instance, data)
        rescue => ex
          puts "*** ERROR: #{ex.class}, #{ex.message}"
          puts ex.backtrace
        end
      end

      :active
    end

    def thread_available?
      @threads.delete_if {|v| !v.alive?}
      @threads.length < @max_threads
    end

    def job_finished(job_instance, job)
      @state_mutex.synchronize do
        state = @boss.job_states[job[:id]]

        if state[:runs_left]
          state[:runs_left] -= 1
          puts "** Finished job #{job[:name]} (#{state[:runs_left]} #{state[:runs_left] == 1 ? "run" : "runs"} left, id #{job[:id]})"
        else
          puts "** Finished job #{job[:name]} (id #{job[:id]})"
        end

        # We're done with this job
        if state[:runs_left] and state[:runs_left] <= 0
          @boss.remove_job(job[:id])

        # Custom time needs to be set for when to run next
        elsif job_instance.respond_to?(:run_at)
          state[:run_at] = job_instance.run_at

        # Can run again
        else
          # Technically it's 0.10 not 0.12 but we want to futz it a bit so it doesn't instantly transition back
          state[:run_at] = Time.now.utc + (job[:transitiontime] * 0.12)
        end

        state[:active] = nil
      end
    end

    def stop
      @threads.each do |thread|
        thread.terminate if thread.alive?
      end
    end
  end
end