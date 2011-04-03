require 'test_helper'
require 'user_file_monitor'

class UserFileMonitorTest < ActiveSupport::TestCase
  def test_user_file_monitoring
    monitor = UserFileMonitor.new
    assert monitor
    monitor.shutdown
  end
end
