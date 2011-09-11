# == Schema Information
# Schema version: 20110813230657
#
# Table name: user_file_nodes
#
#  id           :integer         not null, primary key
#  user_file_id :integer
#  node_id      :integer
#  status       :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#

class UserFileNode < ActiveRecord::Base
    belongs_to :user_file
    belongs_to :node
end
