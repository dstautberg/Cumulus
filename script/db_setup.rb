require_relative "../config/environment"

puts "Creating tables in database #{DB.inspect}"

DB.create_table!(:disks) do
  primary_key :id
  String :path
  Integer :free_space
  Integer :node_id
  DateTime :created_at
  DateTime :updated_at
end

DB.create_table!(:nodes) do
  primary_key :id
  String :name
  String :ip
  Integer :port
  DateTime :checked_in_at
  DateTime :created_at
  DateTime :updated_at
end

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

DB.create_table!(:user_file_nodes) do
  primary_key :id
  Integer :user_file_id
  Integer :node_id
  String :status
  DateTime :created_at
  DateTime :updated_at
end
