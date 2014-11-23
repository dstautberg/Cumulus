require_relative "../config/environment"
require "factory_girl"

# Patch to make Sequel work with Factory Girl.
class Sequel::Model
  def save!
    save
  end
end

FactoryGirl.find_definitions

RSpec.configure do |config|
  config.before(:each) do
    BackupTarget.delete
    UserFile.delete
    Node.delete
    Disk.delete
  end
end

def setup_user_repository(dir="tmp")
  AppConfig.user_repositories = [dir]
  FileUtils.mkpath(dir)
  FileUtils.rm Dir.glob("#{dir}/**/*.*")
  dir
end

def setup_backup_repository(dir="tmp_backup")
  AppConfig.backup_repositories = [dir]
  FileUtils.mkpath(dir)
  FileUtils.rm Dir.glob("#{dir}/**/*.*")
  dir
end
