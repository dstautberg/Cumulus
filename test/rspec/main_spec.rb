require_relative "../test_helper"

describe Main do
  it "starts up and shuts down without errors" do
	AppConfig.user_repositories = ["tmp"]
    AppLogger.debug "Test calling Main.start"
	Main.start
    AppLogger.debug "Test done calling Main.start"
    AppLogger.debug "Test calling Main.stop"
    Main.stop
    AppLogger.debug "Test done calling Main.stop"
  end
end