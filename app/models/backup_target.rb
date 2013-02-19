class BackupTarget < Sequel::Model
    many_to_one :user_file
    many_to_one :disk
end
