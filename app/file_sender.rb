class FileSender
  def initialize
    @active_transfers = 0
    AppLogger.debug "#{self.class.to_s}: initialize complete"
  end

  def start
    AppLogger.debug "#{self.class.to_s}: starting"
  end

  def stop

  end

  def tick
    return @active_transfers >= MaxActiveTransfers
#    Otherwise, it queries the UserFileNode table to see if there is a transfer that is "not started" (order by oldest first?).
#    Initiates a connection to the target node using Connection.stream_file_data, updates the status to "in progress", and updates the number of sends in progress.
#    Sets a callback on the FileStreamer (http://eventmachine.rubyforge.org/EventMachine/FileStreamer.html) to close the file, decrement the number of sends-in-progress, and mark the transfer status to "complete".
  end
end