require_relative "../test_helper"

describe FileSender do
  before do
    @user_dir = setup_user_repository
    @other_node = NodeFactory.create_with_disk
    @sender = FileSender.new
    AppConfig.connect_timeout = 2
    AppConfig.max_active_downloads = 1
  end

  it "tries to send a new file" do
    # Create file that needs to be backed up
    path = File.join(@user_dir, "file_to_send.txt")
    open(path,"w") do |f|
      f.write("this is the data")
    end

    # Create a UserFileNode to trigger a file send
    user_file = UserFile.find_by_full_path(path)
    ufn = UserFileNode.new(:node => @other_node, :status => "not started", :created_at => Time.now, :updated_at => Time.now)
    user_file.add_backup(ufn)

    fake_socket = double("socket")
    fake_socket.stub(:puts)
    fake_socket.stub(:close)
    fake_socket.stub(:gets).and_return(JSON(:port => 10002))
    TCPSocket.stub(:new).and_return(fake_socket)

    @sender.tick
    @sender.active_senders.should == 1

    @sender.stop
    start = Time.now
    while @sender.active_senders > 0 and Time.now - start < 10 do
      sleep 0.5
    end
    @sender.active_senders.should == 0
  end
end
