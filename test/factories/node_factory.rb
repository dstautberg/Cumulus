Factory.define :node do |f|
  f.sequence(:name) {|n| "Node #{n}"}
  f.ip "127.0.0.1"
  f.sequence(:port) {|n| 10000 + n}
  f.checked_in_at {Time.now - 10}
  f.created_at {Time.now}
  f.updated_at {Time.now}
end

class NodeFactory
  def self.create_with_disk
    node = Factory.create(:node)
    node.add_disk(Factory.create(:disk))
    node
  end
end