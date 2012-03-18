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
    @@threads << FileSender.new
    @@threads << BackupFileMonitor.new
    @@threads << NodeBroadcaster.new
    @@threads << FileReceiveListener.new
    @@threads << NodeBroadcastListener.new
    @@threads.each {|t| t.start}
  end

  def self.stop
    @@threads.each {|t| t.stop}
  end
end
