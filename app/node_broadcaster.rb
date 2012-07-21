require 'socket'

class NodeBroadcaster
  def initialize
    AppLogger.debug "#{self.class.to_s}: initialize complete"
  end

  def start
    AppLogger.debug "#{self.class.to_s}: starting"
    @thread = Thread.new do
      while @running do
        tick
        sleep AppConfig.node_broadcaster_sleep_time
      end
    end
  end

  def stop
    @running = false
    @thread.join
  end

  def tick
    # Send out a broadcast packet with information about my node
    # JSON(Node.local)
	
    #MULTICAST_ADDR = "225.4.5.6" 
    #PORT= 5000
    #begin
    #  socket = UDPSocket.open
    #  socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_TTL, [1].pack('i'))
    #  socket.send(ARGV.join(' '), 0, MULTICAST_ADDR, PORT)
    #ensure
    #  socket.close 
    #end
  end
end
