class HueController < Sinatra::Base
  get "/schedules" do
    haml :layout, :layout => false, :locals => {:action => :schedules}
  end
end
