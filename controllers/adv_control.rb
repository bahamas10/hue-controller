class HueController < Sinatra::Base
  get "/adv-control" do
    unless self.config[:ip]
      return redirect to("/config")
    end

    render_view(:adv_control)
  end
end
