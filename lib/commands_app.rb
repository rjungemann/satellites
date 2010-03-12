require 'rubygems'
require 'net/ssh'

module Satellites
  class CommandsApp < Sinatra::Base
    configure do
      set :db, Moneta::File.new(:path => "#{File.dirname(__FILE__)}/../db")
    end
    
    get "/" do
      @models = options.db["satellites"] || []
      
      @commands = @models.collect do |name|
        marshalled_command = options.db["command-#{name}"]
        
        unless marshalled_command 
          model = options.db["satellite-#{name}"]
          satellite = Marshal.load(model)
          
          command = Satellites::RemoteCommand.new(
            satellite.name, satellite.host, satellite.port,
            satellite.username, satellite.password, satellite.directory
          )
          commands = options.db["commands"] || []
          options.db["commands"] = commands << name
          
          options.db["command-#{name}"] = Marshal.dump(command)
        else
          command = Marshal.load(marshalled_command)
        end
        
        command
      end
      
      erb :commands
    end
    
    get "/:name/logs" do
      content_type 'text/plain', :charset => 'utf-8'
      
      model = options.db["command-#{params[:name]}"]
      command = Marshal.load model
      
      command.stdout.reverse.join("\n")
    end
    
    post "/:name/run" do
      name, command = params[:name], params[:command]
      
      @model = options.db["command-#{name}"]
      @command = Marshal.load @model
        
      @command.run command
      
      options.db["command-#{name}"] = Marshal.dump(@command)
      
      redirect "/commands/"
    end
  end
  
  class RemoteCommand
    attr_accessor :name, :host, :port, :username, :password, :directory, :stdout
    
    def initialize name, host, port, username, password, directory
      @name, @host, @port = name, host, port
      @username, @password, @directory = username, password, directory
      @stdout = []
    end
    
    def run command; net_ssh command end
    
    private
    
    def net_ssh *commands
      Net::SSH.start(@host, @username, :password => @password) do |ssh|
        commands.each do |command|
          @stdout << ("#{time} - " + command + " #=> " + (ssh.exec!(command) || "nil"))
        end
      end
    end
    
    def time; Time.now.strftime("%m-%d-%Y_%H-%M-%S") end
  end
end