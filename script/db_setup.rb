require_relative "../config/environment"

puts "Creating tables in database #{DB.inspect}"

# Each record is a computer that is part of the "backup cloud".
DB.create_table!(:nodes) do
  primary_key :id
  String :name
  String :ip
  Integer :port
  DateTime :checked_in_at
  DateTime :created_at
  DateTime :updated_at
end

# Each record is a backup repository that is attached to a node
DB.create_table!(:disks) do
  primary_key :id
  String :path
  Integer :free_space
  Integer :node_id
  DateTime :created_at
  DateTime :updated_at
  DateTime :invalid_at # Set when a disk is no longer accessible
end

# Each record is a file in a user repository that needs to be backed up.
DB.create_table!(:user_files) do
  primary_key :id
  String :directory
  String :filename
  Integer :size
  DateTime :modified_at
  DateTime :deleted_at
  DateTime :created_at
  DateTime :updated_at
end

# Each record is a file that should be backed up to a certain disk on a certain node, but may not have been successfully copied there yet.
DB.create_table!(:backup_targets) do
  primary_key :id
  Integer :user_file_id
  Integer :disk_id
  String :status
  String :error_message
  DateTime :created_at
  DateTime :updated_at
end
