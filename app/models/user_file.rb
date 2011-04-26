# == Schema Information
# Schema version: 20110226233434
#
# Table name: user_files
#
#  id         :integer         not null, primary key
#  directory  :text
#  filename   :text
#  mtime      :datetime
#  size       :integer
#  created_at :datetime
#  updated_at :datetime
#

class UserFile < ActiveRecord::Base
  def self.find_by_full_path(full_path)
    split = File.split(full_path)
    find(:first, :conditions => {:directory => split[0], :filename => split[1]})
  end
end
