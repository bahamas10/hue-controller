class HueController < Sinatra::Base
  get "/control" do
    unless self.config[:ip]
      return redirect to("/config")
    end

    render_view(:control)
  end
end
