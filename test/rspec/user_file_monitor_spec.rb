require_relative "../test_helper"

describe UserFileMonitor do
  before do
    setup_user_repository
    @node1 = NodeFactory.create_with_disk
    @node2 = NodeFactory.create_with_disk
    @monitor = UserFileMonitor.new
    @monitor.start
  end

  after do
    @monitor.stop
  end

  it "handles a new file that needs to be backed up" do
    sleep 3
    UserFile.count.should == 0

    # Create a new file
    open("tmp/new_file.txt","wt") do |f|
      f.write("back me up please")
    end
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
    user_file.backups.size.should == 2
    user_file.backups[0].status.should == "not started"
    user_file.backups[1].status.should == "not started"

    # Wait a little while and make sure the file is not processed again
    sleep 3
    UserFile.count.should == 1
    user_file.reload
    user_file.updated_at.should == old_updated_at
    user_file.backups.size.should == 2
  end
end