require 'test_helper'
require 'em_user_file_monitor'

class UserFileMonitorTest < ActiveSupport::TestCase
  def test_user_file_monitoring
    user_files_dir = "user_files"
    FileUtils.rm_r(user_files_dir) if File.exist?(user_files_dir)
    Dir.mkdir(user_files_dir)
    Cumulus::Application.config.user_repositories = [user_files_dir]    
    @monitor = EmUserFileMonitor.new
    Rails.logger.debug "-----------------------------\nTest starting..."
    
    EM.run do 
        EM.add_periodic_timer(0.1) { @monitor.tick }
      
        EM.add_timer(5) do
            # There isn't anything in the directory yet, so nothing should get put on the queue
            assert_equal 0, @monitor.files_to_backup.size
            Rails.logger.debug "Initial assert passed"
        end
        
        EM.add_timer(6) do          
            # Create a file to be backed up
            Dir.chdir(user_files_dir) do
                File.open("new_file.txt", "w+") do |f|
                    f.write("this is a test file")
                end
            end
            Rails.logger.debug "Created new file"
        end
        
        EM.add_timer(10) do
            assert_equal 1, @monitor.files_to_backup.size
            Rails.logger.debug "Second assert passed"
            EM.stop_event_loop
        end      
    end
    
  end
end
