class HueController < Sinatra::Base
  get "/" do
    unless self.config[:apikey]
      return redirect("/config")
    end

    render_view(:index)
  end
end
