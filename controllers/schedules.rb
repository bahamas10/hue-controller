class HueController < Sinatra::Base
  get "/schedules" do
    render_view(:schedules)
  end
end
