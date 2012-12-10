class HueController < Sinatra::Base
  attr_accessor :config, :hue_data, :communicator, :hub_data, :jobs, :jobs_mtime
  set :public_folder, "public"

  configure :development do
    require "sinatra/reloader"
    register Sinatra::Reloader

    also_reload "./controllers/*.rb"
    also_reload "./helpers/*.rb"
    also_reload "./app.rb"
  end

  def initialize
    super

    if File.exists?("./config/config.yml")
      self.config = YAML::load_file("./config/config.yml")
    else
      self.config = {}
    end

    if File.exists?("./config/hub_data.yml")
      self.hub_data = YAML::load_file("./config/hub_data.yml")
    else
      self.hub_data = {:lights => {}, :groups => {}}
    end

    self.jobs = YAML::load_file("./config/jobs.yml")
    self.jobs_mtime = File.mtime("./config/jobs.yml")
    self.hue_data = YAML::load_file("./config/hue.yml")
    self.communicator = HubCommunicator.new(self.config)
  end

  protected
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

    File.open("./config/config.yml", "w+") do |f|
      f.write(self.config.to_yaml)
    end
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

    File.open("./config/hub_data.yml", "w+") do |f|
      f.write(self.hub_data.to_yaml)
    end
  end

  def update_jobs(reload=true)
    if reload
      if self.jobs_mtime != File.mtime("./config/jobs.yml")
        self.jobs = YAML::load_file("./config/jobs.yml")
      end
    end

    if block_given?
      yield
    end

    File.open("./config/jobs.yml", "w+") do |f|
      f.write(self.jobs.to_yaml)
    end

    self.jobs_mtime = File.mtime("./config/jobs.yml")
  end
end
