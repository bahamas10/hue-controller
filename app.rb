class HueController < Sinatra::Base
  attr_reader :config, :hue_data
  set :public, "public"

  def initialize
    super

    if File.exists?("./config/config.yml")
      @config = YAML::load_file("./config/config.yml")
    else
      @config = {}
    end

    @hue_data = YAML::load_file("./config/hue.yml")
  end

  def save_config(config)
    self.config.merge!(config)

    unless File.directory?("./config/")
      require "fileutils"
      FileUtils.mkdir("./config/")
    end

    File.open("./config/config.yml", "w+") do |f|
      f.write(self.config.to_yaml)
    end
  end
end
