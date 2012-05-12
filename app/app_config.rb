class AppConfig
  class << self
    attr_accessor :user_repositories
    attr_accessor :backup_repositories
    attr_accessor :min_backup_copies
    attr_accessor :max_active_downloads
    attr_accessor :max_active_uploads
    attr_accessor :user_file_monitor_sleep_time
	attr_accessor :node_broadcaster_sleep_time
    attr_accessor :file_sender_sleep_time
    attr_accessor :connect_timeout
  end

  # Default values
  self.user_repositories = []
  self.backup_repositories = []
  self.min_backup_copies = 2
  self.max_active_downloads = 3
  self.max_active_uploads = 3
  self.user_file_monitor_sleep_time = 0.1
  self.node_broadcaster_sleep_time = 10
  self.file_sender_sleep_time = 5
  self.connect_timeout = 10
end
