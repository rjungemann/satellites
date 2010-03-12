require 'rubygems'
require 'sinatra/base'
require 'moneta'
require 'moneta/file'
require "#{File.dirname(__FILE__)}/vendor/spork/lib/spork"
require "#{File.dirname(__FILE__)}/lib/satellites"
require "#{File.dirname(__FILE__)}/lib/satellites_app"
require "#{File.dirname(__FILE__)}/lib/commands_app"
#require "#{File.dirname(__FILE__)}/lib/poller"

#db = Moneta::File.new(:path => "#{File.dirname(__FILE__)}/db")
#poller = Satellites::Poller.new 15 do
#  db["satellites"].each do |name|
#    s = Marshal.load db["satellite-#{s.name}"]
#    
#    s.restart unless s.alive?
#  end
#end

run Rack::URLMap.new({
  "/" => Rack::Cascade.new([
    Satellites::App.new,
    Rack::File.new("#{File.dirname(__FILE__)}/public")
  ]),
  "/commands" => Satellites::CommandsApp.new
})