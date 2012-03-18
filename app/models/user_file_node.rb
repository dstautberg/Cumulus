class UserFileNode < Sequel::Model
    many_to_one :user_file
    many_to_one :node
end
