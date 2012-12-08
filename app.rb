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
    # Make sure something changed so we aren't needlessly writing data
    return if @config.merge(data) == @config
    @config.merge!(data)

    unless File.directory?("./config/")
      require "fileutils"
      FileUtils.mkdir("./config/")
    end

    File.open("./config/config.yml", "w+") do |f|
      f.write(@config.to_yaml)
    end
  end
end
