require "rubygems"
require "bundler/setup"
require "sinatra/base"
require "yaml"
require "json"
require "digest/sha1"

require "./app"
Dir["./controllers/*.rb"].each {|f| require f}

use Rack::CommonLogger, $stdout
run HueController