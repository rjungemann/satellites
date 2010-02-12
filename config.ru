require 'rubygems'
require 'sinatra/base'
require 'moneta'
require 'moneta/file'
require "#{File.dirname(__FILE__)}/lib/satellites"
require "#{File.dirname(__FILE__)}/lib/satellites_app"

run Rack::Cascade.new([
  Satellites::App.new,
  Rack::File.new("#{File.dirname(__FILE__)}/public")
])