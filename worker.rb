require "rubygems"
require "yaml"
require "json"
require "optparse"

options = {:cores => 2}
OptionParser.new do |opts|
  opts.banner = "Usage: worker.rb [options]"
  opts.on("-c", "--cores CORES", "how many cores this computer has") {|c| options[:cores] = c.to_i}
end.parse!(ARGV)

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