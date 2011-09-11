# == Schema Information
# Schema version: 20110813230657
#
# Table name: disks
#
#  id         :integer         not null, primary key
#  path       :string(255)
#  free_space :integer
#  node_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class Disk < ActiveRecord::Base
    belongs_to :node
end
