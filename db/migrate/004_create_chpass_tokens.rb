class CreateChpassTokens < ActiveRecord::Migration
  def self.up
    create_table :chpass_tokens do |t|
      t.column :token,      :string, :unique => true, :null => false
      t.column :account_id, :integer
      t.column :created_at, :timestamp
    end
    add_index :chpass_tokens, :token
  end

  def self.down
    remove_index :chpass_tokens, :token
    drop_table :chpass_tokens
  end
end
