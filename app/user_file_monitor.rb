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
    push_all_user_repositories_onto_queue(@paths_to_process)
    @running = true
    @thread = Thread.new do
      begin
        while @running do
		  AppLogger.debug "UserFileMonitor: calling tick"
          tick
		  AppLogger.debug "UserFileMonitor: tick finished, sleep for #{AppConfig.user_file_monitor_sleep_time} seconds"
          sleep AppConfig.user_file_monitor_sleep_time
		  AppLogger.debug "UserFileMonitor: done sleeping"
        end
		AppLogger.debug "UserFileMonitor: while looped is finished"
	  rescue Exception => e
        AppLogger.error e
      end
    end
  end

  def stop
  	AppLogger.debug "UserFileMonitor.stop started"
    @running = false
    @thread.join
	AppLogger.debug "UserFileMonitor.stop finished"
  end

  def tick
    # Process one entry in the queue
    AppLogger.debug "UserFileMonitor.tick started"
	return if @paths_to_process.empty?
    path = @paths_to_process.pop
    if File.ftype(path) == "file"
      process_file(path)
    else
      process_dir(path)
    end

    # If we're done, then start over
    push_all_user_repositories_onto_queue(@paths_to_process) if @paths_to_process.empty?
	AppLogger.debug "UserFileMonitor.tick finished"
  end

  private

    def push_all_user_repositories_onto_queue(queue)
      AppConfig.user_repositories.each { |dir|
        AppLogger.debug "Queueing path for processing: #{dir}"
        queue.push(dir)
      }
    end

    def process_file(path)
      AppLogger.debug "Processing file #{path}"
      user_file = UserFile.find_by_full_path(path)
      user_file.update_backup_entries
    end

    def process_dir(path)
      AppLogger.debug "Processing dir #{path}"
      AppLogger.debug "Dir.entries(path)=#{Dir.entries(path)}"
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
