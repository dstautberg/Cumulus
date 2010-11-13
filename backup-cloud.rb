require 'java'
require 'file_transfer_handler'
require 'file_map_monitor'
require 'user_file_monitor'
require 'backup_file_monitor'
require 'local_config'

# Start a thread to listen for and reply to file requests, and to accept file responses
file_transfer_handler = FileTransferHandler.new

# Start a thread to check for files that need to be backed up
FileMapMonitor.new(file_transfer_handler)

# Start a thread for monitoring the user repositories:
UserFileMonitor.new

# Start a thread to monitor the backup repositories and verify the backups are readable and valid (save MD5 hash of file data?)
BackupFileMonitor.new(file_transfer_handler)
