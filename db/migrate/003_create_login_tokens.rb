class CreateLoginTokens < ActiveRecord::Migration
  def self.up
    create_table :login_tokens do |t|
      t.column :type,        :string
      t.column :token,       :string, :unique => true, :null => false
      t.column :account_id,  :integer
      t.column :customer_id, :integer
      t.column :created_at,  :timestamp
      t.column :updated_at,  :timestamp
    end
    add_index :login_tokens, :token
    
    Account.find(:all).each {|a| a.renew_login_token_for_agencies}
    Customer.find(:all).each {|c| c.renew_login_token}
  end

  def self.down
    remove_index :login_tokens, :token
    drop_table :login_tokens
  end
end
