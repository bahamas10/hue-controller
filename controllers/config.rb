class HueController < Sinatra::Base
  get "/config" do
    haml :config, :locals => {:action => "config", :no_action_css => true}
  end

  put "/cache-hub" do
    lights = {}
    params[:lights].each {|k, v| lights[k.to_s] = {:name => v["name"].to_s}}

    groups = {}
    params[:groups].each do |k, v|
      groups[k] = {:name => v["name"], :lights => v["lights"] ? v["lights"].map {|l| l.to_i} : []}
    end

    self.save_hub_data(:lights => lights, :groups => groups)
    204
  end

  post "/config" do
    self.save_config(:ip => params[:ip].to_s, :apikey => params[:username].to_s)
    204
  end

  delete "/config/apikey" do
    self.save_config(:apikey => nil)
    204
  end
end