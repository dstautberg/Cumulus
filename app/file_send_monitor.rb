class FileSendMonitor
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
    @running = false
    @senders.each {|s| s[:stop] = true}
    @senders.each {|s| s.join}
    @thread.join
  end

  def active_senders
    @senders = @senders.select { |s| s.alive? }
    @senders.size
  end

  def tick
    AppLogger.debug "#{self.class.to_s}: tick, active_senders=#{active_senders}"
    return if active_senders >= AppConfig.max_active_uploads

    user_file_node = UserFileNode.filter(:status => "not started").order(:updated_at).first
    AppLogger.debug "#{self.class.to_s}: user_file_node=#{user_file_node}"
    if user_file_node
      node = user_file_node.node
      file = user_file_node.user_file
      AppLogger.debug "#{self.class.to_s}: Found file that needs to be sent: #{file.full_path}"

      hash = file_hash(file.full_path)

      # Connect and send the file metadata
      AppLogger.info "#{self.class.to_s}: Connecting to #{node.ip}:#{node.port}"
      socket = TCPSocket.new(node.ip, node.port)
	    metadata = JSON(:path => file.directory, :name => file.filename, :size => file.size, :hash => hash)
	    AppLogger.debug "#{self.class.to_s}: Connected, sending #{metadata}"
      socket.puts(metadata)

      # Read the response containing what port to send the file data to
	    AppLogger.debug "#{self.class.to_s}: Reading response"
      response = socket.gets
      AppLogger.debug "#{self.class.to_s}: response='#{response}'"
      if response
        data_port = JSON.parse(response)["port"]
        AppLogger.debug "#{self.class.to_s}: data_port=#{data_port}"
        sender = FileSender.new(file.full_path, node.ip, data_port)
        sender.start
        @senders << sender
      else
        AppLogger.warn "#{self.class.to_s}: Didn't get proper response from node, unable to send file"
      end
    else
      sleep AppConfig.file_sender_sleep_time
    end
  end

  private

  def file_hash(file)
    t1 = Time.now
    digest = Digest::SHA2.new
    File.open(file, 'rb') do |f|
      while buffer = f.read(MAX_READ_PER_LOOP)
        digest.update(buffer)
      end
    end
    AppLogger.debug "Getting file hash took #{Time.now - t1} secs"
    digest.hexdigest
  end

end