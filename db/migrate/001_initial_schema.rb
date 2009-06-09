class InitialSchema < ActiveRecord::Migration
  def self.up    
   
    create_table :countries do |t|
      t.column :name,             :string
      t.column :name_for_sorting, :string
    end
    
    create_table :addresses do |t|
      t.column :street1,          :string
      t.column :street2,          :string
      t.column :city,             :string
      t.column :province,         :string
      t.column :postal_code,      :string
      t.column :country_id,       :integer      
      t.column :addressable_id,   :integer, :references => nil
      t.column :addressable_type, :string
    end
    
    create_table :accounts do |t|
      # owner
      t.column :owner_id,         :integer, :references => nil # to avoid circularity with users skip the FK
      
      # web access
      t.column :short_name,       :string, :null => false, :unique => true
      t.column :blocked,          :boolean, :default => false, :null => false
      
      # data for our invoices to them, not for their invoices
      t.column :name,             :string, :null => false
      t.column :name_for_sorting, :string
      t.column :bank_account,     :string

      t.column :direct_login,     :boolean, :default => false
      t.column :referer,          :string, :limit => 1024
      t.column :landing_page,     :string, :limit => 1024
    
      # timestamps
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime        
    end
    
    create_table :db_files do |t|
      t.column :data, :binary
    end
    
    create_table :logos do |t|
      t.column :parent_id,    :integer, :references => :logos
      t.column :content_type, :string
      t.column :filename,     :string
      t.column :db_file_id,   :integer
      t.column :thumbnail,    :string
      t.column :size,         :integer
      t.column :width,        :integer
      t.column :height,       :integer
    end

    create_table :fiscal_datas do |t|
      t.column :account_id,       :integer, :null => false
      t.column :name,             :string, :null => false
      t.column :name_for_sorting, :string
      t.column :cif,              :string, :null => false
      t.column :iva_percent,      :decimal, :precision => 10, :scale => 2
      t.column :invoice_footer,   :text
      t.column :irpf_percent,     :decimal, :precision => 10, :scale => 2
      t.column :charges_irpf,     :boolean      
      t.column :logo_id,          :integer
      # has_one :address
    end

    create_table :users do |t|
      # account this user belongs to
      t.column :account_id,               :integer, :null => false

      # personal data
      t.column :first_name,               :string
      t.column :first_name_for_sorting,   :string
      t.column :last_name,                :string
      t.column :last_name_for_sorting,    :string
      
      # timestamps
      t.column :created_at,               :datetime
      t.column :updated_at,               :datetime

      # authentication
      t.column :email,                     :string
      t.column :crypted_password,          :string, :limit => 40
      t.column :salt,                      :string, :limit => 40
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime
      t.column :activation_code,           :string, :limit => 40
      t.column :activated_at,              :datetime

      # blocking flag
      t.column :is_blocked,                :boolean, :default => false      
      t.column :last_seen_at,              :timestamp
    end
    
    create_table :customers do |t|
      t.column :url_id,           :string, :null => false, :references => nil
      t.column :account_id,       :integer, :null => false
      
      t.column :name,             :string
      t.column :name_for_sorting, :string
      t.column :cif,              :string, :null => false
      t.column :discount_percent, :decimal, :precision => 10, :scale => 2
      t.column :notes,            :text

      # has_one :address      
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    add_index :customers, :url_id
    
    create_table :invoices do |t|
      t.column :url_id,               :string,  :null => false, :references => nil
      t.column :account_id,           :integer, :null => false
      t.column :customer_id,          :integer, :null => false
      t.column :number,               :string,  :null => false
      t.column :date,                 :date
      t.column :year,                 :integer # to help in number uniqueness validation

      t.column :account_name,         :string, :null => false
      t.column :account_cif,          :string, :null => false
      t.column :account_street1,      :string
      t.column :account_street2,      :string
      t.column :account_city,         :string
      t.column :account_province,     :string
      t.column :account_postal_code,  :string
      t.column :account_country_id,   :integer, :references => :countries
      t.column :account_country_name, :string
      
      t.column :customer_name,        :string, :null => false
      t.column :customer_cif,         :string, :null => false
      t.column :customer_street1,     :string
      t.column :customer_street2,     :string
      t.column :customer_city,        :string
      t.column :customer_province,    :string
      t.column :customer_postal_code, :string
      t.column :customer_country_id,  :integer, :references => :countries
      t.column :customer_country_name,:string
      
      t.column :irpf_percent,         :decimal, :precision => 10, :scale => 2
      t.column :irpf,                 :decimal, :precision => 10, :scale => 2
      t.column :iva_percent,          :decimal, :precision => 10, :scale => 2
      t.column :iva,                  :decimal, :precision => 10, :scale => 2
      t.column :discount_percent,     :decimal, :precision => 10, :scale => 2
      t.column :discount,             :decimal, :precision => 10, :scale => 2
      t.column :total,                :decimal, :precision => 10, :scale => 2
      t.column :paid,                 :boolean, :null => false, :default => false
      t.column :notes,                :text
      
      t.column :footer,               :text
      t.column :logo_id,              :integer
      
      t.column :created_at,           :datetime
      t.column :updated_at,           :datetime
    end
    add_index :invoices, :url_id
    
    create_table :invoice_lines do |t|
      t.column :invoice_id,  :integer, :null => false
      t.column :amount,      :decimal, :precision => 10, :scale => 2
      t.column :description, :string,  :limit => 1024
      t.column :price,       :decimal, :precision => 10, :scale => 2
      t.column :total,       :decimal, :precision => 10, :scale => 2
    end    
  end

  def self.down
    remove_index :customers, :url_id
    remove_index :invoices, :url_id
    drop_table :invoice_lines
    drop_table :invoices
    drop_table :customers
    drop_table :users
    drop_table :fiscal_datas
    drop_table :logos
    drop_table :db_files
    drop_table :addresses
    drop_table :countries
    drop_table :accounts
  end
  
end
