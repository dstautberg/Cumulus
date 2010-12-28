require 'rubygems'
require 'java'
require 'socket'
require 'json'
require 'lib/hazelcast-1.9.1-SNAPSHOT.jar'

java_import com.hazelcast.core.Hazelcast
java_import com.hazelcast.core.EntryListener

# Listens for updates to the distributed map of files that need to be backed up.
class FileMapMonitor
    include EntryListener

    def initialize(file_transfer_handler)
        puts "FileMapMonitor: Starting"
        @my_node_name = Socket.gethostname.downcase
        @file_transfer_handler = file_transfer_handler
        @files_to_backup = Hazelcast.getMap(LocalConfig.file_map_name)
        @files_to_backup.addEntryListener(self, true)
        puts "FileMapMonitor: Registered entry listener"
        Thread.new { check_existing_map_entries }
    end

    def entryAdded(event)
        process_entry(event.key, event.value)
    end
    
    def entryUpdated(event)
        process_entry(event.key, event.value)
    end

    # Entries removed or evicted:
        # I'm not sure exactly how entries would get evicted, so I'll have to keep an eye on that.
        # Entries should only get removed if they are flagged as deleted and have no registered backups.

    def process_entry(key, value)
        # If the entry was from my own node, ignore it.
        # Is that true?  Should I consider it if I have backup repositories configured?
        puts "[#{Time.now}] Checking entry '#{key}'"
        key, value = YAML.load(key), YAML.load(value)
        return if key['node'] == @my_node_name

        # If the entry was marked as user-deleted
            # Add the backup file to a separate list of deleteable files (distributed list specific to this node).
        # If we are registered to backup this file, or if we're not registered for this file but it has fewer than the required number of registrants
            # Check if it's newer than what we have
            # Check the file size to see if we have space to back it up 
                # Take into account whether we already have a copy that we will be replacing
                # If we're low on space, see if we can free up space using deleted files
                    # Make sure we hold on to deleted files for the minimum number of days (configurable).
                # Check all the backup repositories we have configured.
            # If the file is newer or still needs another backupper, and we have space:
                # Register ourselves as a backupper for this file (status: backup-in-progress).
                # Request a copy of the file from the source node.
       
        value['backuppers'] = [] if value['backuppers'].nil?
        if not value['backuppers'].include?(@my_node_name)
            puts "[#{Time.now}] Adding self to backuppers list and requesting file"
            value['backuppers'] << @my_node_name
            request_queue_name = "file_request_#{key['node']}"
            @files_to_backup.put(key.to_yaml, value.to_yaml) 
            @file_transfer_handler.request_file(key['filepath'], request_queue_name)
        end
    end

    # Run through all the existing entries (right after this node has started up) and make sure each one has appropriate backups.
    # I think we only need to do this once, since new nodes will receive entry listener events.
    # But on the other hand, if a node goes down, we may want its files to start being backed up somewhere else.
    # If I get to the point of having each node update a last_active_time periodically (or figuring out how to access node info in the
    # hazelcast api), then I could keep looping through the keys and making sure the registered backuppers are active (use a reasonable timeout,
    # like 10 minutes, in case a node is just rebooting).
    def check_existing_map_entries
        puts "FileMapMonitor: Starting thread to check existing map entries"
        @files_to_backup.all_keys.each do |key|
            puts "FileMapMonitor: checking #{key}"
            process_entry(key, @files_to_backup[key])
        end
    rescue Exception => e
        puts "Error: #{e}"
        puts e.backtrace
    end
end
