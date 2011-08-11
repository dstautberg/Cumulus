require 'lib/hazelcast-1.9.1-SNAPSHOT.jar'

java_import com.hazelcast.core.Hazelcast
java_import com.hazelcast.core.EntryListener

# Monitors user repositories for files that need to be backed up
class EmUserFileMonitor

  def initialize
    Rails.logger.debug "UserFileMonitor: Starting"
    @my_node_name = Socket.gethostname.downcase
    @paths_to_process = EM::Queue.new
    @files_needing_backup = EM::Queue.new
    push_all_user_repositories(@paths_to_process)
    Rails.logger.debug "UserFileMonitor.initialize complete"
  end

  def push_all_user_repositories(q)
    Cumulus::Application.config.user_repositories.each { |dir|
      Rails.logger.debug "Queueing path for processing: #{dir}"
      q.push(dir)
    }
  end

  def tick
    # Process one entry in the queue
    @paths_to_process.pop do |path|
      if File.ftype(path) == "file"
        process_file(path)
      else
        process_dir(path)
      end
    end

    # Send a file if we have one queued up
    @files_needing_backup.pop do |path|
      # Figure out what node to send the file to.
      # Pick a random one for starters, but make sure it has enough free space to store this file.
      # I need a model for keeping track of other nodes.
      
      # Initiate a TCP connection to the node's IP and port.
      # EventMachine::connect "www.bayshorenetworks.com", 80, DumbHttpClient
      # Send a JSON string containing the message type "file-incoming", and the file path.
      # Receive response as a JSON string that has a status ("OK"), and a port number to send to.
      # Initiate another connection to the new port and send the file data.
      # Note: the initial connection will be triggered here, and we will give it a FileTransferHandler
      # object that is initialized with the file path to send.  The response will be handled by that instance,
      # and it will pass itself to the followup connect that sends the file data.
    end

    # If we're done, then start over
    push_all_user_repositories(@paths_to_process) if @paths_to_process.empty?
  end

  def process_file(path)
    mtime = File.mtime(path)
    size = File.size(path)
    user_file = UserFile.find_by_full_path(path)
    if user_file
      updated = (mtime > user_file.mtime + 2) # use a small buffer to avoid issues with fractional seconds
    else
      updated = true
    end
    if updated
      Rails.logger.debug "File needs backed up: #{path}"
      @files_needing_backup.push(path)      
    end

    # Add file info to the local database too
    UserFile.create!(:filename => filename, :directory => Dir.getwd, :mtime => mtime, :size => size)
  end

  def process_dir(path)
    Dir.foreach(path) do |filename|
      if not [".",".."].include?(filename)
        fullpath = File.join(path, filename)
        Rails.logger.debug "Queueing path for processing: #{fullpath}"
        @paths_to_process.push(fullpath)
      end
    end
    # Check all UserFile's in this directory to see if anything was deleted.
    # If so, notify backuppers that it was deleted.
  end
end
