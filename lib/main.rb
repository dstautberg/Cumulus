require 'em_user_file_monitor'

class Main
  def self.start
#    # Start a thread to listen for and reply to file requests, and to accept file responses
#    file_transfer_handler = FileTransferHandler.new
#
#    # Start a thread to check for files that need to be backed up
#    FileMapMonitor.new(file_transfer_handler)
#
#    # Start a thread for monitoring the user repositories:
#    UserFileMonitor.new
#
#    # Start a thread to monitor the backup repositories and verify the backups are readable and valid (save MD5 hash of file data?)
#    BackupFileMonitor.new(file_transfer_handler)
#
#    loop { sleep 60 }

    @user_file_monitor = EmUserFileMonitor.new

    EM.run do
      EM.add_periodic_timer(0.1) { puts "tick"; @user_file_monitor.tick }
    end

  end
end
