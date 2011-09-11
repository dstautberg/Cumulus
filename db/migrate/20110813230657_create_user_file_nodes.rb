class CreateUserFileNodes < ActiveRecord::Migration
  def self.up
    create_table :user_file_nodes do |t|
      t.integer :user_file_id
      t.integer :node_id
      t.string :status

      t.timestamps
    end
  end

  def self.down
    drop_table :user_file_nodes
  end
end
