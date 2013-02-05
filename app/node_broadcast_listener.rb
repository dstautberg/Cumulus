require 'socket'
require 'ipaddr'

class NodeBroadcastListener
  MULTICAST_ADDR = "225.4.5.6"
  PORT = 11000

  def initialize
    AppLogger.debug "#{self.class.to_s}: initialize complete"
  end

  def start
    AppLogger.debug "#{self.class.to_s}: starting"

    #MULTICAST_ADDR = "225.4.5.6" 
    #PORT = 5000
    #ip =  IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new("0.0.0.0").hton
    #sock = UDPSocket.new
    #sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip)
    #sock.bind(Socket::INADDR_ANY, PORT)
    #loop do
    #  msg, info = sock.recvfrom(1024)
    #  puts "MSG: #{msg} from #{info[2]} (#{info[3]})/#{info[1]} len #{msg.size}" 
    #end
    
    # Check code here too: http://www.ruby-forum.com/topic/200353

    ip =  IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new("0.0.0.0").hton
    sock = UDPSocket.new
    sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip)
    sock.bind(Socket::INADDR_ANY, PORT)
    loop do
      msg, info = sock.recvfrom(1024)
      AppLogger.debug "#{self.class.to_s}: Message from #{info[2]} (#{info[3]})/#{info[1]}, length #{msg.size}:\n#{msg}"
    end
  rescue Exception => e
    AppLogger.debug "#{self.class.to_s}: #{e.inspect}\n#{e.backtrace.join("\n")}"

  def stop

  end
end