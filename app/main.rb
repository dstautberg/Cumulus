load 'config/environment.rb'

class Main
  @@threads = []

  def self.run
    start
    while true do
      sleep 1
    end
  rescue Exception => e
    puts "Error: #{e.inspect}\n#{e.backtrace.join("\n")}"
    stop
  end

  def self.start
    @@threads << UserFileMonitor.new
    @@threads << FileSendMonitor.new
    @@threads << BackupFileMonitor.new
    @@threads << NodeBroadcaster.new
    @@threads << FileReceiveListener.new
    @@threads << NodeBroadcastListener.new
	  AppLogger.debug "Created #{@@threads.size} threads"
    @@threads.each {|t|
		  AppLogger.debug "Starting thread #{t.inspect}"
		  t.start
		  AppLogger.debug "Started thread #{t.inspect}"
	}
  end

  def self.stop
    @@threads.each {|t| t.stop}
  end
end
