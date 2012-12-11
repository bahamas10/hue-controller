class HueController < Sinatra::Base
  get "/control" do
    unless self.config[:ip]
      return redirect to("/config")
    end

    haml :layout, :layout => false, :locals => {:action => :control}
  end
end
