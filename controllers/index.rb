class HueController < Sinatra::Base
  get "/" do
    unless self.config[:apikey]
      return redirect("/config")
    end

    haml :layout, :layout => false, :locals => {:action => :index}
  end
end
