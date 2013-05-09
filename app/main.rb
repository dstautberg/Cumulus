load 'config/environment.rb'

class Main
  @@threads = []

  def self.run
    EventMachine.run do
      EventMachine.start_server("0.0.0.0", 10000, NodeBroadcastListener)
      EventMachine.start_server("0.0.0.0", 0, FileReceiveListener)

      @@threads << UserFileMonitor.new
      @@threads << FileSendMonitor.new
      @@threads << BackupFileMonitor.new
      @@threads << NodeBroadcaster.new
      AppLogger.debug "Created #{@@threads.size} threads"

      @@threads.each { |t|
        AppLogger.debug "Starting thread #{t.class}"
        t.start
        AppLogger.debug "Done starting thread #{t.class}"
      }
    end
  end
end
