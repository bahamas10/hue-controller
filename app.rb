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
    @config.merge!(data)

    current_hash = @config.delete(:hash)
    data_hash = Digest::MD5.hexdigest(@config.to_s)
    # No change
    if data_hash == current_hash
      @config[:hash] = current_hash
      return
    end

    @config[:hash] = data_hash

    unless File.directory?("./config/")
      require "fileutils"
      FileUtils.mkdir("./config/")
    end

    File.open("./config/config.yml", "w+") do |f|
      f.write(@config.to_yaml)
    end
  end
end
