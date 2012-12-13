class ConfigFile
  def self.path=(path); @path = path end
  def self.path; @path end

  def self.file_path(name)
    File.join(self.path, "#{name}.yml")
  end

  def self.load(name)
    file = self.file_path(name)
    if File.exists?(file)
      YAML::load_file(file)
    else
      nil
    end
  end

  def self.write(name, data)
    File.open(self.file_path(name), "w+") do |f|
      f.write(data.to_yaml)
    end
  end

  def self.mtime(name)
    File.mtime(self.file_path(name))
  end

  def self.touch(name)
    file = self.file_path(name)
    unless File.exists?(file)
      File.open(file, "w+") do |f|
        f.write("")
      end
    end
  end
end