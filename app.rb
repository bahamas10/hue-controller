class HueController < Sinatra::Base
  attr_accessor :config, :hue_data, :communicator, :hub_data, :jobs, :jobs_mtime

  set :port, 9222
  set :root, "./"

  configure :development do
    require "sinatra/reloader"
    register Sinatra::Reloader

    also_reload "./controllers/*.rb"
    also_reload "./helpers/*.rb"
    also_reload "./app.rb"
  end

  def initialize
    super

    self.config = ConfigFile.load(:config) || {}
    self.hub_data = ConfigFile.load(:hub_data) || {:lights => {}, :groups => {}}
    self.jobs = ConfigFile.load(:jobs) || []
    self.hue_data = YAML::load_file(File.join("./", "data", "hue.yml"))
    self.communicator = HubCommunicator.new(self.config)
  end

  protected
  def render_view(view, locals={})
    if locals.delete(:layout) == false
      haml view, :layout => false, :locals => locals
    else
      haml :layout, :layout => false, :locals => locals.merge(:action => view)
    end
  end

  def check_data(light, key)
    val = self.hue_data[key][:type] == :float ? light[key].to_f : light[key].to_i
    if val < self.hue_data[key][:min]
      val = self.hue_data[key][:min]
    elsif val > self.hue_data[key][:max]
      val = self.hue_data[key][:max]
    end

    val
  end

  def save_config(data)
    self.config.merge!(data)

    ConfigFile.write(:config, self.config)
  end

  # Save hub data
  def save_hub_data(data)
    self.hub_data.merge!(data)

    current_hash = self.hub_data.delete(:hash)
    data_hash = Digest::SHA1.hexdigest(self.hub_data.to_s)
    # No change
    if data_hash == current_hash
      self.hub_data[:hash] = current_hash
      return
    end

    self.hub_data[:hash] = data_hash

    ConfigFile.write(:hub_data, self.hub_data)
  end

  def update_jobs(reload=true)
    if reload
      if self.jobs_mtime != ConfigFile.mtime(:jobs)
        self.jobs = ConfigFile.load(:jobs) || []
      end
    end

    if block_given?
      yield
    end

    ConfigFile.write(:jobs, self.jobs)
    self.jobs_mtime = ConfigFile.mtime(:jobs)
  end
end
