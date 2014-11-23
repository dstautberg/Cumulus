class NodeFactory
  @@next_port = 10000

  def self.next_port
    @@next_port += 1
  end

  def self.create(options)
    values = {
        :name => SecureRandom.uuid,
        :ip => "127.0.0.1",
        :port => next_port,
        :checked_in_at => Time.now - 10,
        :created_at => Time.now,
        :updated_at => Time.now,
    }
    values = values.merge(options.select { |k, v| values.include?(k) })
    Node.create(values)
  end

  def self.create_with_disk(options={})
    node = create(options)
    node.add_disk(FactoryGirl.create(:disk, options[:disk]))
    node
  end
end
