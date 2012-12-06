class HueController < Sinatra::Base
  get "/schedules" do
    haml :schedules, :locals => {:action => "schedules"}
  end
end