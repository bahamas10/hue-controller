class HueController < Sinatra::Base
  get "/sets" do
    haml :sets, :locals => {:action => "sets"}
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
    require "net/http"
    http = Net::HTTP.new(self.config[:ip], 80)

    self.config[:sets][params[:id].to_i][:lights].each do |light|
      http.request_put("/api/#{self.config[:apikey]}/lights/#{light[:light]}/state", {:on => false}.to_json)
    end

    204
  end

  # Apply a set
  post "/set/apply/:id" do
    set = self.config[:sets][params[:id].to_i]

    require "net/http"
    http = Net::HTTP.new(self.config[:ip], 80)

    # Turn off any lights not mentioned in this group
    if params[:mode] == "off"
      active = {}
      set[:lights].each {|l| active[l[:light]] = true}

      self.hub_data[:lights].each_key do |id|
        next if active[id]

        http.request_put("/api/#{self.config[:apikey]}/lights/#{id}/state", {:on => false}.to_json)
      end
    end

    # Apply the group state
    set[:lights].each do |light|
      data = light.dup
      data.delete(:colormode)

      http.request_put("/api/#{self.config[:apikey]}/lights/#{data.delete(:light)}/state", data.to_json)
    end

    204
  end
end