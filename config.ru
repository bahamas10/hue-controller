require "rubygems"
require "bundler/setup"
require "sinatra/base"
require "yaml"
require "haml"
require "json"
require "digest/sha1"

# Simplify life by forcing an empty force file
unless File.exists?("./config/jobs.yml")
  File.open("./config/jobs.yml", "w+") {|f| f.write([].to_yaml)}
end

Dir["./helpers/*.rb"].each {|f| require f}

require "./app"
Dir["./controllers/*.rb"].each {|f| require f}

use Rack::CommonLogger, $stdout
run HueController