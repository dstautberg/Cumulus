# == Schema Information
# Schema version: 20110813230657
#
# Table name: user_files
#
#  id         :integer         not null, primary key
#  directory  :text
#  filename   :text
#  size       :integer
#  mtime      :datetime
#  deleted    :boolean
#  created_at :datetime
#  updated_at :datetime
#

class UserFile < ActiveRecord::Base
    has_many :backups, :class_name => "UserFileNode", :foreign_key => :user_file_id

    def self.needs_backup?(full_path)
        mtime = File.mtime(full_path)
        size = File.size(full_path)
        directory, filename = File.split(full_path)
        user_file = find(:first, :conditions => {:directory => directory, :filename => filename})
        Rails.logger.debug "Loaded UserFile: #{user_file.inspect}"
        if user_file
          updated = (mtime > user_file.mtime + 1) # use a small buffer to avoid issues with fractional seconds
        else
          updated = true
          user_file = UserFile.new(:directory => directory, :filename => filename)
        end
        if updated
          user_file.update_attributes!(:deleted => false, :mtime => mtime, :size => size)
        end
        return updated
    end
end
