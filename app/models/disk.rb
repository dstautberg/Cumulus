# Table name: disks
#
#  id         :integer         not null, primary key
#  path       :string(255)
#  free_space :integer
#  node_id    :integer
#  created_at :datetime
#  updated_at :datetime
#
class Disk < Sequel::Model
    many_to_one :node
end
