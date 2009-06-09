# == Schema Information
# Schema version: 7
#
# Table name: customers
#
#  id               :integer(11)   not null, primary key
#  url_id           :string(255)   not null
#  account_id       :integer(11)   not null
#  name             :string(255)   
#  name_for_sorting :string(255)   
#  cif              :string(255)   not null
#  discount_percent :decimal(10, 2 
#  notes            :text          
#  created_at       :datetime      
#  updated_at       :datetime      
#

class Customer < ActiveRecord::Base
  belongs_to :account

  has_one  :address, :as => :addressable, :dependent => :destroy
  has_many :invoices, :dependent => :destroy
  
  has_one :login_token, :class_name => 'LoginTokenForCustomer', :dependent => :destroy
  after_create :renew_login_token
    
  add_for_sorting_to :name

  validates_presence_of :name
  validates_associated  :address

  # We do NOT validate the NIF/CIF of customers on
  # purpose. We are forgiving in invoice creation
  # as a design guideline.
  
  def before_create
    compute_and_set_url_id
  end
  
  def before_update
    self_in_db = Customer.find(id, :select => 'id, name')
    compute_and_set_url_id if name != self_in_db.name
  end
  
  def to_param
    url_id
  end

  def renew_login_token
    # It may fail because of the UNIQUE constraint on the token column, very unlikely but possible.
    loop do
      token = FacturagemUtils.random_login_token
      if login_token.nil?
        break if create_login_token(:token => token)
      else
        break if login_token.update_attribute(:token, token)
      end
    end
  end

  def compute_and_set_url_id
    candidate = FacturagemUtils.normalize_for_url_id(name)
    prefix = candidate
    n = 1
    loop do
      c = Customer.find_by_account_id_and_url_id(account_id, candidate)
      break if c.nil?
      return if self == c # perhaps just an accented letter was changed or whatever
      n += 1
      candidate = "#{prefix}-#{n}"
    end
    self.url_id = candidate
  end
  private :compute_and_set_url_id
  
  def can_be_destroyed?
    invoices.empty?
  end
end
