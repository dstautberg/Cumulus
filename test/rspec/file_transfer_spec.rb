require_relative "../test_helper"
require "timeout"

describe "Transfering Files" do
  before do
    AppConfig.connect_timeout = 5
    AppConfig.max_active_downloads = 1
    @user_dir = setup_user_repository
    @other_node = NodeFactory.create_with_disk(:disk => {:path => "tmp_backup"})
    @receive_listener = FileReceiveListener.new(@other_node)
    @receive_listener.start
    @sender = FileSendMonitor.new
  end

  it "sends a file to a backup node successfully" do
    # Create file that needs to be backed up
    path = File.join(@user_dir, "file_to_send.txt")
    file_data = "this is the data"
    open(path,"w") do |f|
      f.write(file_data)
    end

    # Create a UserFileNode to trigger a file send
    user_file = UserFile.find_by_full_path(path)
    target = BackupTarget.new(:disk => @other_node.disks.first)
    user_file.add_backup_target(target)

    @sender.tick
    @sender.active_senders.should == 1

    Timeout.timeout(10) do
      while @sender.active_senders > 0 do
        sleep 0.5
      end
    end
    @sender.active_senders.should == 0

    # Check that the file was written to the backup directory
    backup_file = "tmp_backup/tmp/file_to_send.txt"
    File.exist?(backup_file).should be_true
    File.size(backup_file).should == file_data.size
  end
end
