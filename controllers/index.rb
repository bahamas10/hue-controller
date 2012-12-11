class HueController < Sinatra::Base
  get "/" do
    haml :layout, :layout => false, :locals => {:action => :index}
  end
end
