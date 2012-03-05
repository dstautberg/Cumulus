# == Schema Information
# Schema version: 20110813230657
#
# Table name: nodes
#
#  id            :integer         not null, primary key
#  name          :string(255)
#  ip            :string(255)
#  checked_in_at :datetime
#  created_at    :datetime
#  updated_at    :datetime
#

# When a node starts up, it makes sure it has a node object for itself in the database (update the ip address at 
# this point?), checks the disks that are configured and makes sure they are accessible (updating the Disks in the
# database), and then sends out a broadcast message with the node and disk information.  The content of that message
# will be Node.me.to_transfer_hash, serialized to JSON.  Maybe there will be a status or message type field too, to
# differentiate between "starting", "running", and "shutdown" messages.

class Node < ActiveRecord::Base
    has_many :disks
    
    BackupCopies = 3
    
    @@local = nil

    # Returns the node we are running in
    def self.local
        return @@local if @@local.present?
        # Note: the node should really validate its disks every time it starts up
        @@local = first(:name => Socket.gethostname) || create_local_node
        @@local
    end

    def self.create_local_node
        local = new(:name => Socket.gethostname, :ip => local_ip)
        # check what disks are configured, make sure they are valid, and create Disk models for them 
        local.save!
        local    
    end
        
    def pick_target_nodes(file_size)
        # Pick a random one for starters, but make sure it has enough free space to store this file.
        # Get a randomized list of all nodes except myself
        # Go through the nodes, and the disks for each node, and return the first ones that
        # have enough space.
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