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
        end
      rescue Exception => e
        AppLogger.error e
      end
    end
  end

  def stop
    @senders.each {|s| s[:stop] = true}
    @senders.each {|s| s.join}
  end

  def active_senders
    AppLogger.debug "clearing out dead senders"
    @senders = @senders.select {|s| s.alive?}
    @senders.size
  end

  def tick
    return if active_senders >= AppConfig.max_active_uploads

    user_file_node = UserFileNode.filter(:status => "not started").order(:updated_at).first
    if user_file_node
      node = user_file_node.node
      file = user_file_node.user_file
      AppLogger.debug "Found file that needs to be sent: #{file.full_path}"

      # TODO: Calculate MD5 hash for file
      hash = "1234"

      # Connect and send the file metadata
      AppLogger.info "Connecting to #{node.ip}:#{node.port}"
      socket = TCPSocket.new(node.ip, node.port)
      socket.puts(JSON(:path => file.directory, :name => file.filename, :size => file.size, :hash => hash))

      # Read the response containing what port to send the file data to
      response = socket.gets
      AppLogger.debug "response='#{response}'"
      if response
        data_port = JSON.parse(response)["port"]
        AppLogger.debug "data_port=#{data_port}"
        # Start a new thread to send the file
        @senders << Thread.new do
          begin
            AppLogger.debug "thread started"
            open(file.full_path, "rb") do |f|
              AppLogger.debug "file opened"
              socket = TCPSocket.new(node.ip, data_port)
              AppLogger.debug "connected"
              data = f.read(1000)
              AppLogger.debug "read #{data.size} bytes from file"
              while data.size > 0 and not [:stop] do
                socket.send(data)
                AppLogger.debug "send data"
                data = f.read(1000)
                AppLogger.debug "read #{data.size} more bytes from file"
              end
              AppLogger.debug "done looping"
              socket.close
              AppLogger.debug "socket closed"
            end
          rescue Exception => e
            AppLogger.error e
          end
        end
      else
        AppLogger.warn "Didn't get proper response from node, unable to send file"
      end
    else
      sleep AppConfig.file_sender_sleep_time
    end
  end
end