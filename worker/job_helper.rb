module Worker
  class JobHelper
    def initial_states
      data = {:transitiontime => @job[:transitiontime]}

      # This is the last run, so we need to turn it off
      if @job[:finish_off] and @job_state[:runs_left] <= 1
        data[:on] = false
      end

      states = []
      @job[:lights].each {|l| states.push(data.merge(:light => l))}
      @job[:groups].each {|g| states.push(data.merge(:group => g))}

      states
    end

    def apply_color_trans(states)
      color_at = {:lights => {}, :groups => {}}
      # We've already ran this job, so we're now going to need to flip states back
      if @job_state[:color_at]
        @job_state[:color_at].each do |type, list|
          list.each do |id, at|
            color_at[type][id] = at == :end ? :start : :end
          end
        end

      else
        # Because we automatically apply the initial states when the effect is first queued
        # anything that we list here is immediately being flipped.

        # First run of the job, and we need to flip the state for some of them already
        if @job[:initial_state] and @job_state[:runs_left] == @job[:times_to_run]
          @job[:initial_state].each do |type, id, state|
            color_at[type][id] = state == :end ? :start : :end
          end
        end

        # Initial state
        @job[:lights].each {|l| color_at[:lights][l] ||= :end}
        @job[:groups].each {|g| color_at[:groups][g] ||= :end}
      end

      # Now go through and find the colors
      states.each do |state|
        if state[:group]
          at = color_at[:groups][state[:group]]
        else
          at = color_at[:lights][state[:light]]
        end

        state.merge!(@job["#{at}_color".to_sym])
      end

      # Push the new color states
      @state_mutex.synchronize do
        @job_state[:color_at] = color_at
      end

      states
    end

    def save_state(state)
      @state_mutex.synchronize do
        @job_state.merge!(state)
      end
    end
  end
end