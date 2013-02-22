class UserFile < Sequel::Model
  one_to_many :backup_targets
  attr_accessor :updated

  # Retrieves a UserFile instance given the full path to the file.  Returns nil if the file doesn't exist in the database yet.
  def self.find_by_full_path(path)
    mtime = File.mtime(path)
    size = File.size(path)
    directory, filename = File.split(path)
    user_file = filter(:directory => directory, :filename => filename).first
    if user_file
      user_file.updated = (mtime > user_file.modified_at + 1) # use a small buffer to avoid issues with fractional seconds
      AppLogger.debug "Found existing file: #{path}"
    else
      AppLogger.debug "Found new file: #{path}"
      user_file = UserFile.new(:directory => directory, :filename => filename, :modified_at => mtime,
                               :size => size, :created_at => Time.now)
      user_file.updated = true
    end
    if user_file.updated
      user_file.update(:deleted_at => nil, :modified_at => mtime, :size => size, :updated_at => Time.now)
      AppLogger.debug "Saved file info: #{user_file.inspect}"
    end
    user_file
  rescue Exception => e
    AppLogger.error e
  end

  # This method makes sure this UserFile has the appropriate number of backup targets, if not it creates them.
  # A BackupTarget with a status of "not started" is what triggers the FileSendMonitor to connect to the
  # target node and start sending the file.
  def update_backup_entries
    AppLogger.debug "*** update_backup_entries: updated=#{updated}"
    if updated
      AppLogger.debug "File needs backed up: #{self.inspect}"
      backup_targets.each do |backup|
        # TODO: Think about what all needs to happen here.
        # In particular, should existing transfers for this file be stopped and restarted?
        backup.save(:status => "invalid")
        AppLogger.debug "Invalidated existing backup entry: #{backup.inspect}"
      end
      if backup_targets.size < AppConfig.min_backup_copies
        backup_targets_needed = AppConfig.min_backup_copies - backup_targets.size
        # Get all the disks for all nodes, filter out the ones without enough free space, then choose from them randomly.
        disks = Disk.where("free_space >= ?", self.size).all.shuffle
        backup_targets_needed.times do
          disk = disks.pop
          next if disk.nil?
          self.add_backup_target(BackupTarget.new(:disk => disk, :status => "not started", :created_at => Time.now, :updated_at => Time.now))
        end
      end
    end
  end

  def full_path
    File.join(directory, filename)
  end

#  def modified_at
#    values[:modified_at].nil? ? nil : Time.parse(values[:modified_at])
#  end

#  def created_at
#    values[:created_at].nil? ? nil : Time.parse(values[:created_at])
#  end

#  def updated_at
#    values[:updated_at].nil? ? nil : Time.parse(values[:updated_at])
#  end
end
