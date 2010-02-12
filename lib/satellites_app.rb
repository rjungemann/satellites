module Satellites
  class App < Sinatra::Base
    configure do
      set :db, Moneta::File.new(:path => "#{File.dirname(__FILE__)}/../db")
    end
    
    get "/" do
      @models = options.db["satellites"] || []
      
      @satellites = @models.collect do |model|
        Satellites::RemoteSatellite.new model["name"], model["host"],
          model["port"], model["username"], model["password"], model["directory"],
          model["command"]
      end
      
      erb :index
    end
    
    post "/create" do
      name, host, port = params[:name], params[:host], params[:port]
      username, password = params[:username], params[:password]
      directory, command = params[:directory], params[:command]
      
      @model = options.db["satellite-#{name}"] = {
        "name" => name, "host" => host, "port" => port,
        "username" => username, "password" => password,
        "directory" => directory, "command" => command
      }
      @satellites = options.db["satellites"] || []
      
      options.db["satellites"] = @satellites << @model
      
      redirect "/"
    end
    
    post "/:name/destroy" do
      name = params[:name]
      
      @satellites = options.db["satellites"] || []
      @satellites.reject! { |satellite| satellite["name"] == name }
      
      options.db["satellites"] = @satellites
      
      redirect "/"
    end
    
    post "/:name/:command" do
      name, command = params[:name], params[:command]
      
      @satellites = options.db["satellites"] || []
      @model = options.db["satellite-#{name}"]
      
      @satellite = Satellites::RemoteSatellite.new @model["name"], @model["host"],
        @model["port"], @model["username"], @model["password"], @model["directory"],
        @model["command"]
        
      @satellite.send command
      
      redirect "/"
    end
  end
end