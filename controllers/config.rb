class HueController < Sinatra::Base
  get "/config" do
    haml :config, :locals => {:action => "config", :no_action_css => true}
  end

  put "/cache-data" do
    lights = {}
    params[:lights].each {|k, v| lights[k.to_s] = v.to_s}

    self.save_config(:lights => lights)
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