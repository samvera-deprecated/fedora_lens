module Fedora
  class << self

    def start(war_file)
      require 'childprocess'
      require 'timeout'
      require 'socket'

      port = 8080
      raise "Port #{port} is already in use." if is_port_in_use?(port)
      process = ChildProcess.build("java", "-jar", war_file, '--headless')
      process.detach = true
      process.start
      puts "Started #{war_file}. (#{process.pid}) Waiting until it's listening"
      startup_wait!(port)
    end

    # Wait for the jetty server to start and begin listening for requests
    def startup_wait!(port,  startup_wait = 90)
      begin
      Timeout::timeout(startup_wait) do
        sleep 1 until (is_port_in_use? port)
      end 
      rescue Timeout::Error
        $stderr.puts "Waited #{startup_wait} seconds for jetty to start, but it is not yet listening on port #{port}. Continuing anyway."
      end
    end

    # Check to see if the port is in use so we can raise an error if we have a conflict
    # @param [Fixnum] port the port to check
    # @return [Boolean]
    # @example
    #  Fedora.is_port_in_use?(8983)
    def is_port_in_use?(port)
      begin
        Timeout::timeout(1) do
          begin
            s = TCPSocket.new('127.0.0.1', port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return false
          rescue => e
            $stderr.puts "ERROR: #{e}"
            return false
          end
        end
      rescue Timeout::Error
      end

      return false
    end
  end
end
