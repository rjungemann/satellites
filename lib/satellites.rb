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
    attr_accessor :tmp_path, :dtach_path
    
    def initialize name, port, cmd
      @name, @port, @cmd = name, port, cmd
      
      @tmp_path = "tmp"
      @dtach_path = "dtach"
      
      `mkdir #{@tmp_path}` unless File.exists? @tmp_path
    end
    
    def start
      `#{@dtach_path} -n tmp/#{@name}.dtach #{@cmd}`
      
      File.open("#{@tmp_path}/#{@name}.pid", "w") do |f|
        f.puts(portpid @port)
      end
    end
    
    def restart; stop; start end
    def attach; exec "#{@dtach_path} -a tmp/#{@name}.dtach" end
    
    def stop
      `kill #{portpid @port}`
      `rm #{@tmp_path}/#{@name}.pid`
    end
    
    def alive?; not portpid(@port).blank? end
    
    private
    
    def portpid port
      `lsof -n -i :#{port} | ruby -e "STDIN.gets; puts STDIN.gets.split[1] rescue nil"`
    end
  end
  
  class RemoteSatellite < AbstractSatellite
    attr_reader :stdout
    attr_accessor :tmp_path, :dtach_path
    
    def initialize name, host, port, username, password, directory, cmd
      @name, @host, @port = name, host, port
      @username, @password, @directory, @cmd = username, password, directory, cmd
      @stdout = []
      
      @tmp_path = "tmp"
      @dtach_path = "bin/dtach"
      
      `mkdir #{@tmp_path}` unless File.exists? @tmp_path
    end
    
    def start
      net_ssh "cd #{@directory} && #{@dtach_path} -n tmp/#{@name}.dtach #{@cmd}",
        "cd #{@directory} && echo `#{portpid_string}` > tmp/#{@name}.pid"
    end
    
    def restart
      net_ssh "kill #{portpid_string}",
        "cd #{@directory} && rm #{@tmp_path}/#{@name}.pid",
        "cd #{@directory} && #{@dtach_path} -n tmp/#{@name}.dtach #{@cmd}",
        "cd #{@directory} && echo `#{portpid_string}` > tmp/#{@name}.pid"
    end
    
    def stop
      net_ssh "kill `#{portpid_string}`",
        "cd #{@directory} && rm #{@tmp_path}/#{@name}.pid"
    end
    
    def alive? &block
      data = nil
      
      Net::SSH.start(@host, @username, :password => @password) do |ssh|
        data = ssh.exec!(portpid_string)
      end 
      
      not data.blank?
    end
    
    private
    
    def portpid_string
      "lsof -n -i :#{@port} | ruby -e \"STDIN.gets; puts STDIN.gets.split[1] rescue nil\""
    end
    
    def net_ssh *commands
      Net::SSH.start(@host, @username, :password => @password) do |ssh|
        commands.each do |command|
          ssh.exec!(command) do |channel, stream, data|
            @stdout << data
          end
        end
      end
    end
  end
end