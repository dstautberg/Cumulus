# Table name: user_file_nodes
#
#  id           :integer         not null, primary key
#  user_file_id :integer
#  node_id      :integer
#  status       :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#
class UserFileNode < Sequel::Model
    many_to_one :user_file
    many_to_one :node
end
