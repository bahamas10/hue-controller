require "rubygems"
require "bundler/setup"
require "./app-initializer"

ConfigFile.path = "./config/"

use Rack::Static, :urls => ["/css", "/img", "/js", "/favicon.ico"], :root => "./public/"
use Rack::CommonLogger, $stdout
run HueController