module Satellites
  class App < Sinatra::Base
    configure do
      db = Moneta::File.new(:path => "#{File.dirname(__FILE__)}/../db")
      
      set :db, db
      
      db["satellites"] ||= []
      
      if db["satellites"].size < 1
        Dir.glob("#{File.dirname(__FILE__)}/../media/recipes/*").each do |f|
          eval(File.open(f).read)
        end
      end
    end
    
    get "/" do
      @db = options.db
      @models = @db["satellites"] || []
      
      @satellites = @models.collect do |name|
        model = @db["satellite-#{name}"]
        
        Marshal.load(model)
      end
      
      erb :index
    end
    
    get "/:name/logs" do
      content_type 'text/plain', :charset => 'utf-8'
      
      model = options.db["satellite-#{params[:name]}"]
      satellite = Marshal.load(model)
      
      satellite.stdout.reverse.join("\n")
    end
    
    post "/create" do
      name, host, port = params[:name], params[:host], params[:port]
      username, password = params[:username], params[:password]
      directory, command = params[:directory], params[:command]
      
      @satellite = Satellites::RemoteSatellite.new(name, host, port,
        username, password, directory, command)
      @satellites = options.db["satellites"] || []
      
      options.db["satellites"] = @satellites << name
      options.db["satellite-#{name}"] = Marshal.dump(@satellite)
      
      redirect "/"
    end
    
    post "/:name/destroy" do
      name = params[:name]
      
      @satellites = options.db["satellites"] || []
      @satellites.reject! { |n| name == n }
      
      options.db["satellites"] = @satellites
      options.db["satellites-#{name}"] = nil
      
      commands = options.db["commands"]
      if commands
        commands.reject! { |n| n == name }

        options.db["commands"] = commands
      end

      options.db["command-#{name}"] = nil
      
      redirect "/"
    end
    
    post "/:name/:command" do
      name, command = params[:name], params[:command]
      
      @model = options.db["satellite-#{name}"]
      @satellite = Marshal.load(@model)
        
      @satellite.send command
      
      options.db["satellite-#{name}"] = Marshal.dump(@satellite)
      
      redirect "/"
    end
  end
end