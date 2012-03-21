class AppConfig
  class << self
    attr_accessor :user_repositories
    attr_accessor :min_backup_copies
    attr_accessor :max_active_downloads
    attr_accessor :max_active_uploads
    attr_accessor :user_file_monitor_sleep_time
    attr_accessor :file_sender_sleep_time
  end

  # Default values
  self.user_repositories = []
  self.min_backup_copies = 2
  self.max_active_downloads = 3
  self.max_active_uploads = 3
  self.user_file_monitor_sleep_time = 0.1
  self.file_sender_sleep_time = 1
end