require 'test_helper'
require 'em_user_file_monitor'

class UserFileMonitorTest < ActiveSupport::TestCase
  def test_user_file_monitoring
    user_files_dir = "user_files"
    user_files_subdir = "subdir"
    FileUtils.rm_r(user_files_dir) if File.exist?(user_files_dir)
    Dir.mkdir(user_files_dir)
    Cumulus::Application.config.user_repositories = [user_files_dir]    
    @monitor = EmUserFileMonitor.new
    Rails.logger.debug "-----------------------------\nTest starting..."
    
    EM.run do 
        EM.add_periodic_timer(0.1) { @monitor.tick }
      
        # There isn't anything in the directory yet, so nothing should get put on the queue
        EM.add_timer(2) do
            assert_equal 0, @monitor.files_to_backup.size
            Rails.logger.debug "Initial assert passed"
        end
        
        # Create a file to be backed up
        EM.add_timer(4) do          
            Dir.chdir(user_files_dir) do
                File.open("new_file.txt", "w+") {|f| f.write("this is a test file")}
            end
        end
        
        # Check that the new file was added to the files_to_backup queue
        EM.add_timer(6) do
            assert_equal 1, @monitor.files_to_backup.size
            Rails.logger.debug "Second assert passed"
        end
        
        # Add a file in a subdirectory
        EM.add_timer(8) do
            Dir.chdir(user_files_dir) do
                FileUtils.rm_r(user_files_subdir) if File.exist?(user_files_subdir)
                Dir.mkdir(user_files_subdir)
                Dir.chdir(user_files_subdir) do
                    File.open("new_file2.txt", "w+") {|f| f.write("this is another test file")}
                end
            end
        end
        
        # Check that the new file was added to the queue
        EM.add_timer(10) do
            assert_equal 2, @monitor.files_to_backup.size
            Rails.logger.debug "Third assert passed"
        end

        # Update the file
        EM.add_timer(12) do
            Dir.chdir(user_files_dir) do
                Dir.chdir(user_files_subdir) do
                    File.open("new_file2.txt", "w+") {|f| f.write("updating file")}
                end
            end
        end
        
        # Check that the updated file was added to the queue
        EM.add_timer(14) do
            assert_equal 3, @monitor.files_to_backup.size
            Rails.logger.debug "Fourth assert passed"
        end

        # Delete the file
        EM.add_timer(16) do
            File.join(user_files_dir, user_files_subdir, "new_file2.txt")
        end
        
        # What do I assert here to verify the file was flagged as deleted?
        EM.add_timer(18) do
            
            EM.stop_event_loop
        end
    end
    
  end
end
