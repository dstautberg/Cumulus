class NodeBroadcastListener
  def initialize
    AppLogger.debug "#{self.class.to_s}: initialize complete"
  end

  def start
    AppLogger.debug "#{self.class.to_s}: starting"
  end

  def stop

  end

  def post_init
    puts "NodeBroadcastListener: Received a new connection"
  end
  
  def receive_data(data)

  end
end