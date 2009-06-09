class AddSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.column :session_id, :string, :references => nil
      t.column :data, :text
      t.column :updated_at, :datetime
    end

    add_index :sessions, :session_id
    add_index :sessions, :updated_at
  end

  def self.down
    remove_index :sessions, :session_id
    remove_index :sessions, :updated_at    
    drop_table :sessions
  end
end
