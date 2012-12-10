module Worker
  class Processor
    attr_reader :boss

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

      @threads << Thread.new(self, job) do |processor, job|
        Worker::Job.new.run(processor.boss.job_states[job[:id]], job)
        processor.job_finished(job)
      end

      :active
    end

    def thread_available?
      @threads.delete_if {|v| !v.alive?}
      @threads.length < @max_threads
    end

    def job_finished(job)
      puts "** Finished job #{job[:name]} (#{job[:id]})"

      @state_mutex.synchronize do
        state = @boss.job_states[job[:id]]
        state[:runs_left] -= 1

        # We're done with this job
        if state[:runs_left] <= 0
          @boss.remove_job(job[:id])

        # Can run again
        else
          state[:run_at] = Time.now.utc + (job[:transitiontime] * 0.10)
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