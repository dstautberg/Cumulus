class CreateUserFiles < ActiveRecord::Migration
  def self.up
    create_table :user_files do |t|
      t.text :directory
      t.text :filename
      t.datetime :mtime
      t.integer :size

      t.timestamps
    end
  end

  def self.down
    drop_table :user_files
  end
end
