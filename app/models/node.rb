class Node < Sequel::Model
  one_to_many :disks

  @@local = nil

  # Returns the node we are running in
  def self.local
    return @@local if @@local
    # Note: the node should really validate its disks every time it starts up
    @@local = first(:name => Socket.gethostname) || create_local_node
    @@local
  end

  def self.create_local_node
    local = new(:name => Socket.gethostname, :ip => local_ip)
    # check what disks are configured, make sure they are valid, and create Disk models for them
    local.save
    local
  end

  def self.new_target_nodes(backups, path)
    AppLogger.debug "Node.new_target_nodes"
    new_nodes = []
    AppLogger.debug "new_nodes: #{new_nodes.inspect}"
    if backups.size < AppConfig.min_backup_copies
      diff = AppConfig.min_backup_copies - backups.size
      AppLogger.debug "Need #{diff} more backup nodes"
      AppLogger.debug "Node.all: #{Node.all.inspect}"
      available_nodes = Node.all - [Node.local] - backups.map { |b| b.node }
      AppLogger.debug "available_nodes: #{available_nodes}"
      new_nodes.concat(available_nodes[0, diff])
      AppLogger.debug "New nodes: #{new_nodes.inspect}"
    end
    new_nodes
  end

  def to_transfer_hash
    attributes.merge(:disks => disks)
  end

  private

  # Taken from http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address
  def self.local_ip
    # turn off reverse DNS resolution temporarily
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true
    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1 # this is the ip for google
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end

end
