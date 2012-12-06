class HueController < Sinatra::Base
  get "/config" do
    haml :config, :locals => {:action => "config", :no_action_css => true}
  end

  post "/config" do
    self.save_config(:ip => params[:ip], :apikey => params[:username])
    204

    #url = URI("http://#{params[:ip]}/api")
    #
    #http = Net::HTTP.new(url.host, url.port)
    #res = http.request_post(url.request_uri, {:username => params[:username], :devicetype => params[:devicetype]}.to_json)
    #res = JSON.parse(res.body)
    #
    #res = res.first
    #if res["error"] and res["error"]["type"] == 101
    #  [400, "waiting"]
    #elsif res["error"]
    #  [400, res["error"]["description"]]
    #elsif res["success"]
    #  self.save_config(:ip => params[:ip], :apikey => params[:username])
    #
    #  [200, "success"]
    #end
  end

  delete "/config/apikey" do
    self.save_config(:apikey => nil)
    204
  end
end