require 'pathname'

PREFIX = Pathname.new(File.dirname(__FILE__)).realpath

begin
  require 'jeweler'
  
  Jeweler::Tasks.new do |s|
    s.name = "jeweler"
    s.executables = "satellites"
    s.summary = "Satellites is a process management tool"
    s.email = "roger@thefifthcircuit.com"
    s.homepage = "http://github.com/thefifthcircuit/satellites"
    s.description = "Use Satellites to daemonize and manage your processes. Start and stop your databases, your servers, and your workers easily using this tool. Uses dtach to create its processes."
    s.authors = ["Roger Jungemann"]
    s.files =  FileList[
      "[A-Z]*",
      "{bin, lib, public, views}/**/*"
    ]
    s.add_dependency 'net/ssh'
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

desc "Install dtach."
task :install_dtach do
  sh "cd vendor && curl -O http://thefifthcircuit.com/media/dtach-0.8.zip"
  sh "cd vendor && unzip dtach-0.8.zip && rm dtach-0.8.zip"
  sh "cd vendor/dtach-* && ./configure --prefix=#{PREFIX} && make && sudo mv dtach ../../bin/"
  sh "cd vendor && rm -rf dtach-*"
  sh "rm -rf vendor/__MACOSX" if File.exists?("vendor/__MACOSX")
end