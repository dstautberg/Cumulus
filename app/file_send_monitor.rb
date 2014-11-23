class FileSendMonitor
  def initialize
    @senders = []
    AppLogger.debug "#{self.class.to_s}: initialize complete"
  end

  def start
    AppLogger.debug "#{self.class.to_s}: starting"
    @running = true
    @thread = Thread.new do
      while @running do
        begin
          tick
        rescue Exception => e
          AppLogger.error e
        end
      end
    end
  end

  def stop
    @running = false
    @senders.each { |s| s[:stop] = true }
    @senders.each { |s| s.join }
    @thread.join
  end

  def active_senders
    @senders = @senders.select { |s| s.alive? }
    @senders.size
  end

  def tick
    AppLogger.debug "#{self.class.to_s}: tick, active_senders=#{active_senders}"
    return if active_senders >= AppConfig.max_active_uploads

    backup_target = BackupTarget.next
    AppLogger.debug "#{self.class.to_s}: user_file_node=#{backup_target.inspect}"
    if backup_target
      begin
        node = backup_target.disk.node
        file = backup_target.user_file
        AppLogger.debug "#{self.class.to_s}: Found file that needs to be sent: #{file.full_path}"

        hash = file_hash(file.full_path)

        # Connect and send the file metadata
        AppLogger.info "#{self.class.to_s}: Connecting to #{node.ip}:#{node.port}"
        socket = TCPSocket.new(node.ip, node.port)
        directory = file.directory.gsub(":", "_") # if the directory includes a colon (like with a drive letter), convert it to an underscore
        target_path = File.join(backup_target.disk.path, directory)
        metadata = JSON(:path => target_path, :name => file.filename, :size => file.size, :hash => hash)
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
          backup_target.started
        else
          AppLogger.warn "#{self.class.to_s}: Didn't get proper response from node, unable to send file"
        end
      rescue Exception => e
        backup_target.error(e)
      end
    else
      sleep AppConfig.file_sender_sleep_time
    end
  end

  private

  MAX_READ_PER_LOOP = 100000

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