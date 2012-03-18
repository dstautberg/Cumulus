# Monitors user repositories for files that need to be backed up.
class UserFileMonitor

  def initialize
    @local_node = Node.local
    @my_node_name = Socket.gethostname.downcase
    @paths_to_process = SizedQueue.new(1000)
    @files_needing_backup = SizedQueue.new(1000)
    AppLogger.debug "#{self.class.to_s}: initialize complete"
  end

  def start
    AppLogger.debug "#{self.class.to_s}: starting"
    push_all_user_repositories_onto_queue(AppConfig.user_repositories, @paths_to_process)
  end

  def stop

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

    # If we're done, then start over
    push_all_user_repositories_onto_queue(config, @paths_to_process) if @paths_to_process.empty?
  end

  private

    def push_all_user_repositories_onto_queue(user_repositories, queue)
      user_repositories.each { |dir|
        AppLogger.debug "Queueing path for processing: #{dir}"
        q.push(dir)
      }
    end

    def initiate_file_send
      # Send a file if we have one queued up
      @files_needing_backup.pop do |path|
        # Figure out what nodes to send the file to.
        target_node = Node.me.pick_target_nodes(File.size(path))

        # Ok, so the process is: File is found locally that has been updated, all existing backups
        # of the file are marked as invalid, another thread monitors that list and sees a file that needs
        # backups, picks the targets nodes, initiates the transfers, and links the target nodes to
        # the user file with an initial status of pending.  When the transfer finishes it is marked
        # succeeded.  There may be a timeout process there too if it sits pending for too long, but
        # I also may put a limit on number of concurrent transfers, so I'll have to make sure the
        # thread that initiates the transfers is not queueing things up too fast.

        # I also need to figure out how the target node will know that it's backup got invalidated
        # so it can delete the file (not right away, but eventually).

        # Initiate a TCP connection to the node's IP and port.
        # EventMachine::connect "www.bayshorenetworks.com", 80, DumbHttpClient


        # Send a JSON string containing the message type "file-incoming", and the file path.
        # Receive response as a JSON string that has a status ("OK"), and a port number to send to.
        # Initiate another connection to the new port and send the file data.
        # Note: the initial connection will be triggered here, and we will give it a FileTransferHandler
        # object that is initialized with the file path to send.  The response will be handled by that instance,
        # and it will pass itself to the followup connect that sends the file data.
      end
    end

    def process_file(path)
      mtime = File.mtime(path)
      size = File.size(path)
      user_file = UserFile.find_by_full_path(path)
      if user_file
        updated = (mtime > user_file.mtime + 2) # use a small buffer to avoid issues with fractional seconds
      else
        user_file = UserFile.new
        updated = true
      end
      user_file.save!(:filename => filename, :directory => Dir.getwd, :mtime => mtime, :size => size)

      # Changes here. If the file has been updated it should invalidate all the UserFileNode entries (are they deleted
      # or just marked invalid?).  Also, even if the file is not updated, we still want to verify that the file has the
      # required number of UserFileNode entries.  If the file needs more UserFileNode entries, we should create them
      # here and mark them "pending".
      # I'm thinking deleting the UserFileNode entries if the file is updated would be cleaner.  Because we can
      # follow that up by making sure the node has enough entries.  My only concern is that the old nodes are not
      # notified that their backup copy is no longer needed.

      if updated
        AppLogger.debug "File needs backed up: #{path}"
        user_file.backups.each do |backup|
          backup.update_attributes!(:status => "invalid")
        end
      end
    end

    def process_dir(path)
      Dir.foreach(path) do |filename|
        if not [".",".."].include?(filename)
          fullpath = File.join(path, filename)
          AppLogger.debug "Queueing path for processing: #{fullpath}"
          @paths_to_process.push(fullpath)
        end
      end
      # Check all UserFile's in this directory to see if anything was deleted.
      # If so, notify backuppers that it was deleted.
    end
end
