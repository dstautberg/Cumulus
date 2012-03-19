class UserFile < Sequel::Model
  one_to_many :backups, :class => :UserFileNode, :key => :user_file_id
  attr_accessor :updated

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

  def update_backup_entries
    AppLogger.debug "*** update_backup_entries: updated=#{updated}"
    if updated
      AppLogger.debug "File needs backed up: #{self.inspect}"
      backups.each do |backup|
        backup.save(:status => "invalid")
        AppLogger.debug "Invalidated existing backup entry: #{backup.inspect}"
      end
      nodes = Node.new_target_nodes(backups, size)
      nodes.each do |node|
        add_backup(UserFileNode.new(:node => node,
                                    :status => "not started",
                                    :created_at => Time.now,
                                    :updated_at => Time.now))
        AppLogger.debug "Added new backup entry: #{backups.last.inspect}"
      end
    end
  end

  def modified_at
    values[:modified_at].nil? ? nil : Time.parse(values[:modified_at])
  end

  def created_at
    values[:created_at].nil? ? nil : Time.parse(values[:created_at])
  end

  def updated_at
    values[:updated_at].nil? ? nil : Time.parse(values[:updated_at])
  end
end
