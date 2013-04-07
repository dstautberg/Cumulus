class Disk < Sequel::Model
  many_to_one :node
end
