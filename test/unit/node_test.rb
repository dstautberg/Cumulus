require 'test_helper'

class NodeTest < ActiveSupport::TestCase

  def test_local_node_creation
    repos = ["/mnt/#{UUID.generate}", "/mnt/#{UUID.generate}"]
    repos.each {|dir| Dir.mkdir(dir) unless Dir.exist?(dir) }
    Cumulus::Application.config.backup_repositories = repos

    @local_node = Node.local
    assert_equal 2, @local_node.disks.size
  end
end
