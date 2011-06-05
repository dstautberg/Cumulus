require 'lib/hazelcast-1.9.1-SNAPSHOT.jar'

java_import com.hazelcast.core.Hazelcast
java_import com.hazelcast.core.EntryListener

# Monitors user repositories for files that need to be backed up.
# This is the EventMachine version.
class EmUserFileMonitor

  attr_reader :files_to_backup

  def initialize
    puts "UserFileMonitor: Starting"
    @files_to_process = EM::Queue.new
    @files_to_backup = EM::Queue.new
    push_all_user_repositories
    Rails.logger.debug "UserFileMonitor.initialize complete"
  end

  def push_all_user_repositories
    Cumulus::Application.config.user_repositories.each { |dir|
      Rails.logger.debug "Pushing #{dir}"
      @files_to_process.push(File.expand_path(dir))
    }
  end

  def tick
    Rails.logger.debug "@files_to_process.size=#{@files_to_process.size}"
    @files_to_process.pop do |path|
      Rails.logger.debug "Processing #{path}"
      Rails.logger.debug "File.exists?(path)=#{File.exists?(path)}"
      if File.exists?(path)
        Rails.logger.debug "File.ftype(path)=#{File.ftype(path)}"
        if File.ftype(path) == "file"
          process_file(path)
        else
          Dir.foreach(path) do |filename|
            if not [".",".."].include?(filename)
              fullpath = File.join(path, filename)
              Rails.logger.debug "Pushing #{fullpath}"
              @files_to_process.push(fullpath)
            end
          end
        end
      else
        Rails.logger.debug "Path does not exist: #{path}"
      end
    end
    # If we're done, then start over
    Rails.logger.debug "Processed all repositories. Starting over..."
    push_all_user_repositories if @files_to_process.empty?
  end

  def process_file(full_path)
    Rails.logger.debug "Processing file #{full_path}"
    mtime = File.mtime(full_path)
    size = File.size(full_path)
    user_file = UserFile.find_by_full_path(full_path)
    if user_file
      user_file.update_attributes!(:deleted => false)
      updated = (mtime > user_file.mtime + 2) # use a small buffer to avoid issues with fractional seconds
    else
      updated = true
    end
    if updated
      Rails.logger.debug "File needs to be backed up: #{full_path}"
      dir, filename = File.split(full_path)
      UserFile.create!(:filename => filename, :directory => dir, :mtime => mtime, :size => size)
      @files_to_backup.push(full_path)
    end
  end

  def process_dir(dir)
    Rails.logger.debug "Processing dir #{dir}"
    Dir.chdir(dir) do
      # Mark all UserFiles in this directory as deleted. They will get set back to not-deleted
      # as we process each one, so any file we don't find will keep the deleted flag.
      UserFile.update_all({:deleted => true}, ["directory=?", dir])
      Dir.foreach(".") do |entry|
        if entry != "." and entry != ".."
          if File.directory?(entry)
            process_dir(entry)
          else
            process_file(entry)
          end
        end
      end
      # Check if all entries in the UserFile table with this directory to see if anything was deleted.
      UserFile.find(:conditions => ["directory=? and deleted=?", dir, true]).each do |file|
        # TODO: Notify all nodes with a backup copy that the file was deleted.
    
      end
    end
  end

end
