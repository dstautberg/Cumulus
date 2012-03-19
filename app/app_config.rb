class AppConfig
  class << self
    attr_accessor :user_repositories
    attr_accessor :max_active_transfers
    attr_accessor :user_file_monitor_sleep_time
    attr_accessor :min_backup_copies
  end

  # Default values
  self.user_repositories = []
  self.max_active_transfers = 10
  self.user_file_monitor_sleep_time = 0.1
  self.min_backup_copies = 2
end