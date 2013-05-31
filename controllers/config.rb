class HueController < Sinatra::Base
  get "/config" do
    render_view(:config, :skip_action_css => true)
  end

  put "/cache-hub" do
    lights = params[:lights] || {}
    lights.each do |k, v|
      lights[k.to_s] = {:name => v["name"].to_s}
    end

    groups = params[:groups] || {}
    groups.each do |k, v|
      group_lights = v["lights"] ? v["lights"].map {|l| l.to_i} : []
      groups[k] = {:name => v["name"], :lights => group_lights}
    end

    self.save_hub_data(:lights => lights, :groups => groups)
    204
  end

  post "/config" do
    self.save_config(:ip => params[:ip].to_s, :apikey => params[:username].to_s, :advanced => params[:advanced] == "true")
    204
  end

  delete "/config/apikey" do
    self.save_config(:apikey => nil)
    204
  end
end
