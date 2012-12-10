require "rubygems"
require "yaml"
require "json"
require "optparse"

options = {:cores => 2, :env => "development"}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby worker.rb [options]"
  opts.on("-c", "--cores CORES", "how many cores this computer has") {|c| options[:cores] = c.to_i}
  opts.on("-e", "--environment ENV", "what environment to run as") {|e| options[:env] = e}
end.parse!(ARGV)

ENV["RUBY_ENV"] = options[:env]

$stdout.sync = true

require "./worker/job_helper.rb"

Dir["./helpers/*.rb"].each {|f| require f}
Dir["./worker/**/*.rb"].each {|f| require f}
runner = Worker::Runner.new(options)

begin
  runner.start
rescue Interrupt
  runner.stop
end