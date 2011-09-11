class CreateDisks < ActiveRecord::Migration
  def self.up
    create_table :disks do |t|
      t.string :path
      t.integer :free_space
      t.integer :node_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :disks
  end
end
