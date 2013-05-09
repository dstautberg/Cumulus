class FileReceiveListener < EM::Connection

  def receive_data(data)
    AppLogger.debug "#{self.class.to_s}: received #{data.size} bytes of data"
  end

  #def initialize(node=Node.local)
  #  @node = node
  #  AppLogger.debug "#{self.class.to_s}: using node #{@node.inspect}"
  #  @receivers = []
  #  AppConfig.max_active_downloads.times do
  #    @receivers << FileReceiver.new(@node)
  #  end
  #  AppLogger.debug "#{self.class.to_s}: initialize complete"
  #end
  #
  #def start
  #  AppLogger.debug "#{self.class.to_s}: starting"
  #  server = TCPServer.open("0.0.0.0", 0)
  #  AppLogger.debug "#{self.class.to_s}: Started server on #{server.addr[1]}"
  #  @running = true
  #  AppLogger.debug "#{self.class.to_s}: updating node with port"
  #  @node.update(:port => server.addr[1])
  #  @listener = Thread.new do
  #    begin
  #      while @running do
  #        AppLogger.debug "#{self.class.to_s}: about to accept connections"
  #        Thread.start(server.accept) do |client|
  #          AppLogger.debug "Got connection from #{client.inspect}"
  #          AppLogger.debug "@receivers=#{@receivers.inspect}"
  #          receiver = @receivers.detect { |r| r.available? }
  #          AppLogger.debug "receiver=#{receiver.inspect}"
  #          if receiver.nil?
  #            AppLogger.debug "No available receivers. Disconnecting client."
  #            client.write(JSON(:error => "No available receivers. Try again later."))
  #            client.close
  #          else
  #            AppLogger.debug "Handing off to receiver: #{receiver.inspect}"
  #            receiver.handle(client)
  #          end
  #        end
  #      end
  #    rescue Exception => e
  #      AppLogger.error e
  #    end
  #  end
  #  AppLogger.debug "#{self.class.to_s}: done starting"
  #rescue Exception => e
  #  AppLogger.error e
  #end
  #
  #def stop
  #  AppLogger.debug "FileReceiveListener.stop started"
  #  @running = false
  #  @receivers.each { |r| r.stop }
  #  @receivers.each { |r| r.join }
  #  AppLogger.debug "FileReceiveListener.stop finished"
  #end
end