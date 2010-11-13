require 'java'
require 'rubygems'
require 'lib/hazelcast-1.9.1-SNAPSHOT.jar'

java_import com.hazelcast.core.Hazelcast
java_import com.hazelcast.core.EntryListener

# Monitor the backup repositories and verify the backups are readable and valid (according to the MD5 hash).
class BackupFileMonitor
    def initialize(file_transfer_handler)
        puts "BackupFileMonitor: Starting"
        @file_transfer_handler = file_transfer_handler
        Thread.new { monitor_backups }
    end

    def monitor_backups
        puts "BackupFileMonitor: Starting thread to monitor backup files"
        # Do I start with all the keys in the file map that I am registered to backup, or the files in my backup file system?
        # I feel like I need to check both.

        # Request a resend if the validation check fails
    rescue Exception => e
        puts "Error: #{e}"
        puts e.backtrace
    end
end
