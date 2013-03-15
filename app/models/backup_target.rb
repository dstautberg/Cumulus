class BackupTarget < Sequel::Model
  many_to_one :user_file
  many_to_one :disk

  def after_initialize
    self.status ||= "not-started"
    self.created_at ||= Time.now
    self.updated_at ||= Time.now
    super
  end

  def self.next
    # TODO: Also check for 'invalid' status?
    # To consider: Make sure we don't have two transfers in progress for the same file.  Maybe the file FileSender thread
    # should be responsible for checking the invalid status, then stopping the transfer and resetting the status to "not started".
    # Note: I need to clarify what this use case is.  What sets the status to invalid?
    filter(:status => "not-started").order(:updated_at).first
  end

  def started
    update(:status => "in-progress")
  end

  def error(e)
    update(:status => "error", :error_message => e.inspect)
  end

  def invalid
    save(:status => "invalid")
  end
end
