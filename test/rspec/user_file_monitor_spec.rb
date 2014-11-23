require_relative "../test_helper"

describe UserFileMonitor do
  before do
    setup_user_repository
    AppConfig.user_file_monitor_sleep_time = 0
    @monitor = UserFileMonitor.new
    @monitor.start
  end

  after do
    @monitor.stop
  end

  context "handles a new file that needs to be backed up" do

    context "when there is only one node" do
      it "flags the file for backup to the same node" do
        # Create a new file
        open("tmp/new_file.txt", "wt") { |f| f.write("back me up please") }
        file_modified_time = Time.now
        sleep 3

        # New file should be added as needing backed up
        UserFile.count.should == 1
        user_file = UserFile.first
        user_file.directory.should == "tmp"
        user_file.filename.should == "new_file.txt"
        user_file.size.should be > 10
        user_file.modified_at.should be_within(1.0).of(file_modified_time)
        user_file.deleted_at.should be_nil
        user_file.created_at.should be_within(4.0).of(Time.now)
        user_file.updated_at.should be_within(4.0).of(Time.now)
        old_updated_at = user_file.updated_at
        user_file.backup_targets.size.should == 1
        user_file.backup_targets[0].status.should == "not started"

        # Wait a little while and make sure the file is not processed again
        sleep 3
        UserFile.count.should == 1
        user_file.reload
        user_file.updated_at.should == old_updated_at
        user_file.backup_targets.size.should == 1
      end
    end

    context "when there is a second node" do
      it "flags the file for backup to both nodes" do
        @node2 = NodeFactory.create_with_disk

        # Make sure nothing happens right away
        sleep 3
        UserFile.count.should == 0

        # Create a new file
        open("tmp/new_file.txt", "wt") { |f| f.write("back me up please") }
        file_modified_time = Time.now
        sleep 3

        # New file should be added as needing backed up
        UserFile.count.should == 1
        user_file = UserFile.first
        user_file.directory.should == "tmp"
        user_file.filename.should == "new_file.txt"
        user_file.size.should be > 10
        user_file.modified_at.should be_within(1.0).of(file_modified_time)
        user_file.deleted_at.should be_nil
        user_file.created_at.should be_within(4.0).of(Time.now)
        user_file.updated_at.should be_within(4.0).of(Time.now)
        old_updated_at = user_file.updated_at
        user_file.backup_targets.size.should == 2
        user_file.backup_targets[0].status.should == "not started"
        user_file.backup_targets[1].status.should == "not started"

        # Wait a little while and make sure the file is not processed again
        sleep 3
        UserFile.count.should == 1
        user_file.reload
        user_file.updated_at.should == old_updated_at
        user_file.backup_targets.size.should == 2
      end
    end
  end
end
