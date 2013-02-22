# Monitors user repositories for files that need to be backed up.
class UserFileMonitor
  include Sys

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
      while @running do
        begin
          tick
        rescue Exception => e
          AppLogger.error e
        end
        sleep AppConfig.user_file_monitor_sleep_time
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
    verify_backup_repositories

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

    def verify_backup_repositories
      AppConfig.backup_repositories.each do |repo|
        disk = Disk.where(:node_id => @local_node.id, :path => repo).first
        if File.exist?(repo)
          stat = Filesystem.stat(root_path(repo))
          free_space = stat.block_size * stat.blocks_free
          if disk.nil?
            @local_node.add_disk(:path => repo, :free_space => free_space)
          else
            disk.update(:free_space => free_space)
          end
        else
          AppLogger.debug "Backup repository is invalid: #{repo}"
          # I don't know if we want to delete the disk entry right away.  If some node is currently trying to backup a file to
          # this disk and it temporarily becomes invalid, we can let it keep trying.  Although something will have to decide
          # that the backup is pending for too long and pick a new backup target.  Likewise, we'll need some logic somewhere
          # to decide that the disk entry has been invalid for too long and remove it.
          # Compromise: Maybe we can set an invalid_at timestamp at this point, so other logic can use that timestamp
          # to determine when to delete the disk.
          disk.update(:invalid_at => Time.now) unless disk.nil?
        end
      end
    end

  def root_path(path)
    split = File.split(path)
    while true do
      pre_split = split[0]
      split = File.split(split[0])
      break if split[0] == pre_split
    end
    split[0]
  end

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
