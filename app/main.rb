require 'user_file_monitor'

class Main
  def self.start
    config = Cumulus::Application.config
    user_file_monitor = UserFileMonitor.new(config)
    file_sender = FileSender.new(config)
    backup_file_monitor = BackupFileMonitor.new(config)
    node_broadcaster = NodeBroadcaster.new(config)
    EM.run do
      EM.add_periodic_timer(0.1) { user_file_monitor.tick }
      EM.add_periodic_timer(1.0) { file_sender.tick }
      EM.add_periodic_timer(1.0) { backup_file_monitor.tick }
      EventMachine::start_server "0.0.0.0", nil, FileReceiveListener
      EventMachine::start_server "0.0.0.0", nil, NodeBroadcastListener
      EM.add_periodic_timer(10.0) { node_broadcaster.tick }
    end
  end
end
