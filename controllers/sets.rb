class HueController < Sinatra::Base
  get "/sets" do
    haml :layout, :layout => false, :locals => {:action => :sets}
  end

  # Create set
  post "/set" do
    self.config[:sets] ||= {}

    set_id = self.config[:sets].keys.max.to_i + 1

    self.config[:sets][set_id] = {:name => params[:name]}
    self.config[:sets][set_id][:lights] = params[:lights].map do |id, light|
      data = {:light => id.to_s, :on => light[:on] == "true", :colormode => light[:colormode]}

      if data[:on]
        data[:bri] = self.check_data(light, :bri)

        if light[:colormode] == "ct"
          data[:ct] = self.check_data(light, :ct)
        elsif light[:colormode] == "xy"
          data[:xy] = [light[:xy][0].to_f, light[:xy][1].to_f]
          data[:xy].delete_if {|v| v > 1 or v < 0}

        elsif light[:colormode] == "hs"
          data[:hue] = self.check_data(light, :hue) if light[:hue]
          data[:sat] = self.check_data(light, :sat) if light[:sat]
        end
      end

      data
    end

    self.save_config(:sets => self.config[:sets])

    204
  end

  # Show the state of a set
  get "/set/state/:id" do
    haml :set_state, :layout => false, :locals => {:set => self.config[:sets][params[:id].to_i]}
  end

  # Delete set
  delete "/set/:id" do
    self.config[:sets].delete(params[:id].to_i)
    self.save_config(:sets => self.config[:sets])

    204
  end

  # Turn all the lights in a set off
  delete "/set/apply/:id" do
    set = self.config[:sets][params[:id].to_i]

    states = []
    if set[:effect]
      set[:lights].each {|l| states.push(:light => l, :on => false)}
      set[:groups].each {|g| states.push(:group => g, :on => false)}
    else
      set[:lights].each {|l| states.push(:light => l[:light], :on => false)}
    end

    self.communicator.apply_states(states)

    204
  end

  # Apply a set
  post "/set/apply/:id" do
    set = self.config[:sets][params[:id].to_i]

    # Turn off any lights not mentioned in this set
    if params[:mode] == "off"
      active_lights, active_groups = {}, {}

      if set[:effect]
        set[:lights].each {|l| active_lights[l] = true}
        set[:groups].each {|g| active_groups[g] = true}
      else
        set[:lights].each {|l| active_lights[l[:light]] = true}
      end

      states = []
      unless active_lights.empty?
        self.hub_data[:lights].each do |id|
          states.push(:light => id, :on => false) unless active_lights[id]
        end
      end

      unless active_groups.empty?
        self.hub_data[:groups].each do |id|
          states.push(:group => id, :on => false) unless active_lights[id]
        end
      end

      self.communicator.apply_states(states)
    end

    # Need to figure out the initial state so it can be pushed
    if set[:effect]
      effect = self.communicator.apply_initial_effect(set)
      self.update_jobs do
        self.jobs.delete_if {|v| v[:id] == effect[:id]}
        self.jobs.push(effect.merge(:reset_state => true))
      end

    # Straight set, nothing fancy
    else
      states = set[:lights].map do |light|
        state = light.dup
        state.delete(:colormode)
        state
      end

      self.communicator.apply_states(states)
    end

    204
  end

end
