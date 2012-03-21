class FileSender
  def initialize
    @senders = []
    AppLogger.debug "#{self.class.to_s}: initialize complete"
  end

  def start
    AppLogger.debug "#{self.class.to_s}: starting"
    @running = true
    @thread = Thread.new do
      begin
        while @running do
          tick
          sleep AppConfig.file_sender_sleep_time
        end
      rescue Exception => e
        AppLogger.error e
      end
    end
  end

  def stop

  end

  def tick
    return if @senders.size >= AppConfig.max_active_uploads

    user_file_node = UserFileNode.filter(:status => "not started").order(:updated_at).first
    node = user_file_node.node
    file = user_file_node.user_file

    # Calculate MD5 hash for file
    hash = "1234"

    # Connect and send the file metadata
    socket = TCPSocket.new(node.ip, node.port)
    socket.puts(JSON(:path => file.directory, :name => file.filename, :size => file.size, :hash => hash))

    # Read the response containing what port to send the file data to
    response = JSON(socket.gets)
    data_port = response["port"]

    # Open the file and send it to the new port
    open(file.fullpath, "rb") do |f|
      socket = TCPSocket.new(node.ip, data_port)
      data = f.read(1000)
      while data.size > 0 do
        socket.send(data)
        data = f.read(1000)
      end
      socket.close
    end
  end
end