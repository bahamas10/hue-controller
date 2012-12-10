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

          states = klass.new(processor.state_mutex, processor.boss.job_states[data[:id]], job).run
          @boss.communicator.apply_states(states)

          processor.job_finished(data)
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

    def job_finished(job)
      @state_mutex.synchronize do
        state = @boss.job_states[job[:id]]
        state[:runs_left] -= 1

        puts "** Finished job #{job[:name]} (#{state[:runs_left]} #{state[:runs_left] == 1 ? "run" : "runs"} left, id #{job[:id]})"

        # We're done with this job
        if state[:runs_left] <= 0
          @boss.remove_job(job[:id])

        # Can run again
        else
          # Technically it's 0.10 not 0.12 but we want to futz it a bit so it doesn't instantly transition back
          state[:run_at] = Time.now.utc + (job[:transitiontime] * 0.12)
          state[:active] = nil
        end
      end
    end

    def stop
      @threads.each do |thread|
        thread.terminate if thread.alive?
      end
    end
  end
end