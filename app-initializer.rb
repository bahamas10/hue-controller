require "rubygems"
require "rack"
require "sinatra/base"
require "yaml"
require "haml"
require "json"
require "digest/sha1"

Dir["./helpers/*.rb"].each {|f| require f}
Dir[File.join("./", "controllers", "*.rb")].each {|f| require f}
require "./app"