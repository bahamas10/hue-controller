class HueController < Sinatra::Base
  get "/effects" do
    haml :effects, :locals => {:action => "effects", :no_action_css => true}
  end

  post "/effect/pulse" do
    effect = {}
    effect[:name] = params[:name].to_s
    effect[:type] = :pulse

    if params[:lights].is_a?(Array)
      effect[:lights] = params[:lights].map {|l| l.to_i}
    else
      effect[:lights] = []
    end

    if params[:groups].is_a?(Array)
      effect[:groups] = params[:groups].map {|g| g.to_i}
    else
      effect[:groups] = []
    end

    effect[:times_to_run] = params[:times_to_run].to_i
    effect[:transitiontime] = params[:transitiontime].to_i
    effect[:start_color] = {:hue => params[:start_color][:h].to_i, :sat => params[:start_color][:s].to_i, :bri => params[:start_color][:v].to_i}
    effect[:end_color] = {:hue => params[:end_color][:h].to_i, :sat => params[:end_color][:s].to_i, :bri => params[:end_color][:v].to_i}
    effect[:alternate] = params[:alternate] == "true"
    effect[:id] = Digest::SHA1.hexdigest("#{effect.to_s}#{Time.now.utc.to_f}")

    if params[:save_set]
      effect[:effect] = true

      self.config[:sets] ||= {}
      set_id = self.config[:sets].keys.max.to_i + 1

      self.config[:sets][set_id] = effect
      self.save_config(:sets => self.config[:sets])

    else
      effect = self.communicator.apply_initial_effect(effect)

      self.update_jobs do
        self.jobs.push(effect)
      end
    end

    204
  end

  delete "/effect/:id" do
    self.update_jobs do
      self.jobs.delete_if {|v| v[:id] == params[:id]}
    end

    204
  end

  delete "/effects" do
    self.update_jobs(false) { self.jobs.clear }
    204
  end
end