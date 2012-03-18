class Main
  def self.start
    @threads = [
      UserFileMonitor.new,
      FileSender.new,
      BackupFileMonitor.new,
      NodeBroadcaster.new,
      FileReceiveListener.new,
      NodeBroadcastListener.new
    ]
    @threads.each {|t| t.start}
  end

  def stop
    @threads.each {|t| t.stop}
  end
end
