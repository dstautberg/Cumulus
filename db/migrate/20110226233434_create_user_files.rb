class CreateUserFiles < ActiveRecord::Migration
  def self.up
    create_table :user_files do |t|
      t.text :directory
      t.text :filename
      t.integer :size
      t.datetime :mtime
      t.boolean :deleted
      t.timestamps
    end
    add_index :user_files, [:directory, :filename, :deleted]
  end

  def self.down
    drop_table :user_files
  end
end
