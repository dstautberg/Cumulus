class FileSender
  MaxActiveTransfers = 10 # put in app config? or make it something that can adjust based on cpu/disk/network load?

  def initialize(config)
    @active_transfers = 0
  end

  def tick
    return @active_transfers >= MaxActiveTransfers
#    Otherwise, it queries the UserFileNode table to see if there is a transfer that is "not started" (order by oldest first?).
#    Initiates a connection to the target node using Connection.stream_file_data, updates the status to "in progress", and updates the number of sends in progress.
#    Sets a callback on the FileStreamer (http://eventmachine.rubyforge.org/EventMachine/FileStreamer.html) to close the file, decrement the number of sends-in-progress, and mark the transfer status to "complete".
  end
end