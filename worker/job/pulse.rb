module Worker
  module Job
    class Pulse < Worker::JobHelper
      def initialize(mutex, job_state, job)
        @state_mutex, @job_state, @job = mutex, job_state, job
      end

      def run
        states = self.initial_states
        self.apply_color_trans(states)
      end
    end
  end
end