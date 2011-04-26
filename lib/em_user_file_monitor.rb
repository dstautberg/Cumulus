require 'lib/hazelcast-1.9.1-SNAPSHOT.jar'

java_import com.hazelcast.core.Hazelcast
java_import com.hazelcast.core.EntryListener

# Monitors user repositories for files that need to be backed up
class EmUserFileMonitor

  def initialize
    puts "UserFileMonitor: Starting"
    @my_node_name = Socket.gethostname.downcase
    @q = EM::Queue.new
    push_all_user_repositories(@q)
    puts "UserFileMonitor.initialize complete"
  end

  def push_all_user_repositories(q)
    Cumulus::Application.config.user_repositories.each { |dir|
      puts "* pushing #{dir}"
      q.push(dir)
    }
  end

  def tick
    @q.pop do |path|
      if File.ftype(path) == "file"
        process_file(path)
      else
        Dir.foreach(path) do |filename|
          if not [".",".."].include?(filename)
            fullpath = File.join(path, filename)
            puts "* pushing #{fullpath}"
            @q.push(fullpath)
          end
        end
      end
    end
    # If we're done, then start over
    push_all_user_repositories(@q) if @q.empty?
  end

  def process_file(full_path)
    mtime = File.mtime(full_path)
    size = File.size(full_path)
    user_file = UserFile.find_by_full_path(full_path)
    if user_file
      updated = (mtime > user_file.mtime + 2) # use a small buffer to avoid issues with fractional seconds
      @files_to_backup.push(full_path)
    else
      updated = true
    end
    if updated
      puts "[#{Time.now}] Updating entry for: #{full_path}"
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
