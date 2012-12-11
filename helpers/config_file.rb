class ConfigFile
  def self.path=(path); @path = path end
  def self.path; @path end

  def self.load(name)
    file = File.join(self.path, "#{name}.yml")
    if File.exists?(file)
      YAML::load_file(file)
    else
      nil
    end
  end

  def self.write(name, data)
    File.open(File.join(self.path, "#{name}.yml"), "w+") do |f|
      f.write(data.to_yaml)
    end
  end

  def self.file_path(name)
    File.join(self.path, "#{name}.yml")
  end

  def self.mtime(name)
    File.mtime(self.file_path(name))
  end
end