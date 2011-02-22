# == Schema Information
# Schema version: 20101227021239
#
# Table name: user_files
#
#  id         :integer         not null, primary key
#  directory  :string(255)
#  filename   :string(255)
#  mtime      :datetime
#  size       :integer
#  created_at :datetime
#  updated_at :datetime
#

class UserFile < ActiveRecord::Base
end
