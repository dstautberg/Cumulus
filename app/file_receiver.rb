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
    AppLogger.debug "FileReceiver.receive(): data=#{data.inspect}"
    path = data["path"]
    name = data["name"]
    size = data["size"]
    hash = data["hash"]

    disk = @node.disks.detect { |d| path.start_with?(d.path) }
    if disk.nil?
      @client.puts(JSON(:error => "Invalid backup path.", :retry => false))
      @client.close and return
    elsif size > disk.free_space
      @client.puts(JSON(:error => "Not enough space on backup device.", :retry => false))
      @client.close and return
    end

    # Create the directory and delete the file if it already exists
    directory = File.split(path)[0]
    FileUtils.mkdir_p(directory) unless File.exists?(directory)
    FileUtils.rm(path) if File.exists?(path)
    
    # Should I have "reserved" space for files that are being transferred, so I don't over-commit?
    # If I just have a separate field for reserved space somewhere, I need it to be updated whenever data is actually
    # written for it to be accurate.
    # I could preallocate the space by writing bytes to the file until the size is reached, then seek back to the
    # beginning to start writing the real data, but that causes twice as many writes.

    # Start a separate listener to receive the binary data for this file
    listener = TCPServer.open("0.0.0.0", 0)

    # Send back the port number and close the first connection
    @client.puts(JSON(:port => listener.addr[1]))
    @client.close

    # Wait for the second connection.  I don't need to spawn a thread when that happens since there
    # should only be one thing connecting to it.
    client2 = Timeout.timeout(10) { listener.accept }

    # Start writing the data to the file
    open(path, "wb") do |f|
        AppLogger.debug "FileReceiver: opened #{path}"
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
