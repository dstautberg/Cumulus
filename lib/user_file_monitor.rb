require 'rubygems'
require 'socket'
require 'java'
require 'lib/hazelcast-1.9.1-SNAPSHOT.jar'

#require 'json'
#require 'time'
#require 'user_file'

java_import com.hazelcast.core.Hazelcast
java_import com.hazelcast.core.EntryListener

# Monitors user repositories for files that need to be backed up
class UserFileMonitor

    def initialize
        puts "UserFileMonitor: Starting"
        @my_node_name = Socket.gethostname.downcase
        @file_map = Hazelcast.getMap(Cumulus::Application.config.file_map_name)
        Thread.new { monitor_user_files }
    end
      
    def shutdown
        Hazelcast.shutdownAll
        # stop the file monitor thread too?
    end

    def monitor_user_files
        puts "UserFileMonitor: Starting thread to monitor user files"
        # Consider adding sleeps in here to avoid excessive cpu usage.
        while true do
            Cumulus::Application.config.user_repositories.each do |dir|
                process_dir(dir)
            end
            sleep 10
        end
    rescue Exception => e
        puts "Error: #{e}"
        puts e.backtrace
    end

    def process_file(filename)
        #puts "UserFileMonitor: Checking file #{filename}"
        full_path = File.expand_path(filename)
        mtime = File.mtime(full_path)
        size = File.size(full_path)
        key = {'node' => @my_node_name.to_s, 'filepath' => full_path.to_s}
        entry = @file_map.get(key.to_yaml)
        if entry
            entry = YAML.load(entry)
            updated = (mtime > Time.parse(entry["last_updated"]) + 2)
        else
            updated = true
        end
        if updated
            puts "[#{Time.now}] Updating map entry for: #{filename}"
            puts "[#{Time.now}] full_path = #{full_path}"
            puts "[#{Time.now}] key = #{key.inspect}"
            entry = {'last_updated' => mtime.to_s, 'size' => size.to_s}
            @file_map.put(key.to_yaml, entry.to_yaml)
        end

        # Add file info to the local database too
        UserFile.create!(:filename => filename, :directory => Dir.getwd, :mtime => mtime, :size => size)
    end

    def process_dir(dir)
        #puts "UserFileMonitor: Checking dir #{dir}"
        Dir.chdir(dir) do
            Dir.foreach(".") do |entry|
                if entry != "." and entry != ".."
                    if File.directory?(entry)
                        process_dir(entry)
                    else
                        process_file(entry)
                    end
                end
                # Check all entries in the distributed map for this directory to see if anything was deleted
                    # If so, flag it in the distributed map as deleted.
                    # If it has already been flagged as deleted, and has no registered backups, then we should be clear to remove it from the map.
            end
        end
    end
end
