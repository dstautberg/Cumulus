class FileReceiveListener
  def initialize
    @receivers = []
    AppConfig.max_active_downloads.times do
      @receivers << FileReceiver.new
    end
    AppLogger.debug "#{self.class.to_s}: initialize complete"
  end

  def start
    AppLogger.debug "#{self.class.to_s}: starting"
    server = TCPServer.open(0)
    Node.local.update(:port => server.addr[1])
    loop do
      client = server.accept
      AppLogger.debug "Got connection from #{client.inspect}"
      receiver = @receivers.find {|r| r.available?}
      if receiver.nil?
        AppLogger.debug "No available receivers. Disconnecting client."
        client.write(JSON(:error => "No available receivers. Try again later."))
        client.close
      else
        receiver.handle(client)
      end
    end
  rescue Exception => e
    AppLogger.error e
  end

  def stop
    @receivers.each {|r| r.stop}
    @receivers.each {|r| r.join}
  end
end