require_relative "../test_helper"

describe Main do
  it "starts up and shuts down without errors" do
    Main.start
    Main.stop
  end
end