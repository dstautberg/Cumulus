class FileReceiver
  def initialize(node)
    @node = node
    @available = true
  end
  
  def available?
	@available
  end

  def handle(client)
    @available = false
    @client = client
    AppLogger.debug "FileReceiver.handle starting receive thread"
    @receive_thread = Thread.new { self.receive }
  end

  def stop
    @receive_thread.stop if @receive_thread
  end

  def join
    @receive_thread.join if @receive_thread
  end

  def receive
    AppLogger.debug "FileReceiver.receive"
  
    # Initially we get just get the file metadata
    data = JSON(@client.gets)
    path = data["path"]
    name = data["name"]
    size = data["size"]
    hash = data["hash"]

    # Figure out which disk we will save the file to. Return the path on the backup node?
    disk = @node.disks.detect { |d| d.free_space >= size }

    if disk.nil?
        @client.puts(JSON(:error => "Not enough free disk space."))
        @client.close
    end

    # Create the path and delete the file if it already exists
    backup_dir = File.join(disk.path, path)
    FileUtils.mkdir_p(backup_dir) if !File.exists?(backup_dir)
    backup_path = File.join(backup_dir, name) 
    FileUtils.rm(backup_path) if File.exists?(backup_path)
    
    # Should I have "reserved" space for files that are being transferred, so I don't over-commit?

    # Start a separate listener to receive the binary data for this file
    listener = TCPServer.open("0.0.0.0", 0)

    # Send back the port number and close the first connection
    @client.puts(JSON(:port => listener.addr[1]))
    @client.close

    # Wait for the second connection.  I don't need to spawn a thread when that happens since there
    # should only be one thing connecting to it.
    client2 = Timeout.timeout(10) { listener.accept }

    # Start writing the data to the file
    open(backup_path, "wb") do |f|
        AppLogger.debug "FileReceiver: opened #{backup_path}"
		while true
            data = client2.recv(1000)
            AppLogger.debug "FileReceiver: got #{data.size} bytes"
            break if data.size <= 0
            AppLogger.debug "FileReceiver: writing data"
            f.write(data)
            AppLogger.debug "FileReceiver: data written"
        end
    end
    AppLogger.debug "FileReceiver: done writing to file"

    # Possible future enhancement: Monitor the free space on the disk while we're receiving the file.
    # If the disk doesn't have enough space anymore, see if another disk does.
    # If so, move the already saved data from the old disk to the new disk and continue writing to
    # the new disk.

    @available = true
  rescue Exception => e
    AppLogger.error e
  end
end
