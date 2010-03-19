require 'rubygems'
require 'net/ssh'

class Object
  def blank?
    self.nil? || (self.respond_to?(:empty?) && self.empty?)
  end
end

module Satellites
  class AbstractSatellite
    def start; end
    def restart; end
    def stop; end
    def alive?; end
  end
  
  class Satellite < AbstractSatellite
    attr_accessor :name, :port, :command, :tmp_path, :dtach_path, :stdout
    
    def initialize name, port, command
      @name, @port, @command = name, port, command
      @tmp_path, @dtach_path = "tmp", "/Volumes/SpliceProtDB/dtach"
      @stdout = []
      
      run "mkdir #{@tmp_path}" unless File.exists?(@tmp_path)
    end
    
    def start
      run "#{@dtach_path} -n tmp/#{@name}.dtach #{@command}"
      
      File.open("#{@tmp_path}/#{@name}.pid", "w") do |f|
        f.puts(portpid)
      end
    end
    
    def restart; stop; start end
    def attach; exec "#{@dtach_path} -a tmp/#{@name}.dtach" end
    
    def stop
      run "kill -9 #{portpid}"
      run "rm #{@tmp_path}/#{@name}.pid"
    end
    
    def alive?; not portpid.blank? end
    
    private
    
    def run command
      @stdout << ("#{time} - " + command + " #=> " + (`#{command}` || "nil") + "\n")
    end
    
    def portpid_string
      "lsof -n -i :#{@port} | ruby -e \"STDIN.gets; puts STDIN.gets.split[1] rescue nil\""
    end
    
    def portpid; run portpid_string end
    def time; Time.now.strftime("%m-%d-%Y_%H-%M-%S") end
  end
  
  class RemoteSatellite < AbstractSatellite
    attr_accessor :stdout
    attr_accessor :tmp_path, :dtach_path
    attr_accessor :name, :host, :port, :username, :password, :directory, :command
    
    def initialize name, host, port, username, password, directory, command
      @name, @host, @port = name, host, port
      @username, @password, @directory, @command = username, password, directory, command
      @tmp_path, @dtach_path = "tmp", "/Volumes/SpliceProtDB/bin/dtach"
      @stdout = []
      
      net_ssh %{ruby -e "Dir.mkdir '#{@tmp_path}' unless File.exists? '#{@tmp_path}'"}
    end
    
    def start
      net_ssh "cd #{@directory} && #{@dtach_path} -n tmp/#{@name}.dtach #{@command}",
        "cd #{@directory} && echo `#{portpid_string}` > tmp/#{@name}.pid"
    end
    
    def restart
      net_ssh "kill -9 #{portpid_string}",
        "cd #{@directory} && rm #{@tmp_path}/#{@name}.pid",
        "cd #{@directory} && #{@dtach_path} -n tmp/#{@name}.dtach #{@command}",
        "cd #{@directory} && echo `#{portpid_string}` > tmp/#{@name}.pid"
    end
    
    def stop
      net_ssh "kill -9 `#{portpid_string}`",
        "cd #{@directory} && rm #{@tmp_path}/#{@name}.pid"
    end
    
    def alive?
      data = nil
      
      Net::SSH.start(@host, @username, :password => @password) do |ssh|
        data = ssh.exec!(portpid_string)
      end 
      
      not data.blank?
    end
    
    private
    
    def net_ssh *commands
      Net::SSH.start(@host, @username, :password => @password) do |ssh|
        commands.each do |command|
          @stdout << ("#{time} - " + command + " #=> " + (ssh.exec!(command) || "nil") + "\n")
        end
      end
    end
    
    def portpid_string
      "lsof -n -i :#{@port} | ruby -e \"STDIN.gets; puts STDIN.gets.split[1] rescue nil\""
    end
    
    def time; Time.now.strftime("%m-%d-%Y_%H-%M-%S") end
  end
end