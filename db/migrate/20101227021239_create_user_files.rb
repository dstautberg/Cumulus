class CreateUserFiles < ActiveRecord::Migration
  def self.up
    create_table :user_files do |t|
      t.string :directory
      t.string :filename
      t.datetime :mtime
      t.integer :size

      t.timestamps
    end
  end

  def self.down
    drop_table :user_files
  end
end
