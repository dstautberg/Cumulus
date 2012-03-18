class AppConfig
  class << self
    attr_accessor :user_repositories
    attr_accessor :max_active_transfers
  end

  # Default values
  self.user_repositories = []
  self.max_active_transfers = 10
end