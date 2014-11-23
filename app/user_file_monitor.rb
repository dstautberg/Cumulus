# Monitors user repositories for files that need to be backed up.
class UserFileMonitor
  include Sys

  def initialize
    @local_node = Node.local
    @my_node_name = Socket.gethostname.downcase
    AppLogger.debug "#{self.class.to_s}: initialize complete"
  end

  def start
    AppLogger.debug "#{self.class.to_s}: starting"
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
    AppLogger.debug "UserFileMonitor: stopping"
    @running = false
    @thread.join
    AppLogger.debug "UserFileMonitor: stopped"
  end

  def tick
    AppLogger.debug "UserFileMonitor.tick started"
    verify_backup_repositories

    AppConfig.user_repositories.each do |path|
      process_dir(path)
    end

    AppLogger.debug "UserFileMonitor.tick finished"
  end

  private

  def verify_backup_repositories
    AppConfig.backup_repositories.each do |repo|
      disk = Disk.where(:node_id => @local_node.id, :path => repo).first
      if File.exist?(repo)
        stat = Filesystem.stat(root_path(repo))
        bytes_free = stat.block_size * stat.blocks_free
        AppLogger.debug "Backup repository #{repo} has #{bytes_free} bytes free"
        if disk.nil?
          @local_node.add_disk(:path => repo, :free_space => bytes_free)
        else
          disk.update(:free_space => bytes_free)
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

  def process_file(path)
    AppLogger.debug "Processing file #{path}"
    user_file = UserFile.find_by_full_path(path)
    user_file.update_backup_entries
    sleep 0.1
  rescue Exception => e
    AppLogger.error e
  end

  def process_dir(path)
    AppLogger.debug "Processing dir #{path}"
    AppLogger.debug "Dir.entries(path)=#{Dir.entries(path)}"
    Dir.foreach(path) do |filename|
      if not [".", ".."].include?(filename)
        fullpath = File.join(path, filename)
        if File.ftype(fullpath) == "file"
          process_file(fullpath)
        else
          process_dir(fullpath)
        end
      end
    end
      # Also check all UserFile's in this directory to see if anything was deleted.
      # If so, notify backuppers that it was deleted.
  rescue Exception => e
    AppLogger.error e
  end
end
