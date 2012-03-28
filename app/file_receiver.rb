class FileReceiver
  attr_reader :available

  def initialize
    @available = true
  end

  def handle(client)
    @client = client
    @available = false
    @metadata_thread = Thread.new { self.receive_file }
  end

  def stop
    @metadata_thread.stop
  end

  def join
    @metadata_thread.join
  end

  def receive_file
    # Initially we get just get the file metadata
    data = JSON(@client.gets)
    @path = data["path"]
    @name = data["name"]
    @size = data["size"]
    @hash = data["hash"]

    # Make sure we have enough space for the file
    # Should I have "reserved" space for files that are being transferred, so I don't over-commit?

    # Start a separate listener to receive the binary data for this file
    @listener = TCPServer.open(0)

    # Send back the port number and close the first connection
    @client.puts(JSON(:port => @listener.addr[1]))
    @client.close

    # Wait for the second connection
    # Note: I'll need a timeout here.
    client = server.accept

    # Open the file in binary write mode
    # Loop: receive a chunk of data: recv(maxlen), write it to the file
    # When the connection is closed by the sender, close the file
    # Mark myself as available, and exit the thread
  end
end
