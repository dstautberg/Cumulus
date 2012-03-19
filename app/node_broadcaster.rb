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
  end
end
