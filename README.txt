Satellites
by Roger Jungemann (MIT License)

Satellites is a library for starting and stopping servers, locally or
remotely, either through the command line, Ruby scripts, or a web service.

Ideally, you would run it on a separate domain from the host whose processes you want to observe. Then you can use the web interface to start those processes.

It uses dtach to daemonize processes but new kinds of "Satellites" can be
created by subclassing AbstractSatellite.

Examples of using the Ruby library:

	# local version
	servers = [Satellites::Satellite.new "redis", 6379, "redis-server redis.conf"]
	
	# remote version
	servers = [
	  Satellites::RemoteSatellite.new "redis", "127.0.0.1", 6379,
	    "username", "password", "path/to/server",
	    "bin/redis-server redis.conf"
	]
	servers.each { |server| puts server.start }
	
Examples using the command line:

	# local version
	satellites redis 6379 start "redis-server redis.conf"
	satellites redis 6379 stop
	
	# remote version
	satellites redis 127.0.0.1 6379 username password "path/to/server" start "redis-server redis.conf"
	satellites redis 127.0.0.1 6379 username password "path/to/server" stop
	
The server can be started from the included "config.ru" script. You can type in "rackup config.ru -p4567" to start a simple instance of the service. Then browse to "http://localhost:4567/" and create a process from there.

Any command which isn't daemonized can be turned into a satellite. Examples:

	rackup config.ru -p4568
	thin start -R config.ru -p4569
	./script/server -p3000
	redis-server redis.conf
	
You must have ssh access to the host in question, the command to run the server, and what port the server runs on. Then a dtach process is created which runs the server in a separate process. That process can be easily monitored and started/stopped/restarted if necessary.

Requirements:

	net/ssh gem for the command-line tool and Ruby library
	sinatra, moneta, and spork gems for the web service 
	dtach must be in the path of the computer you are connecting to.

To Do:

	Allow for periodic monitoring of process with the option to restart, controllable through the web service, Ruby, or the command line