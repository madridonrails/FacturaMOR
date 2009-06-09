# == Schema Information
# Schema version: 7
#
# Table name: accounts
#
#  id               :integer(11)   not null, primary key
#  owner_id         :integer(11)   
#  short_name       :string(255)   not null
#  blocked          :boolean(1)    not null
#  name             :string(255)   not null
#  name_for_sorting :string(255)   
#  bank_account     :string(255)   
#  direct_login     :boolean(1)    
#  referer          :string(1024)  
#  landing_page     :string(1024)  
#  created_at       :datetime      
#  updated_at       :datetime      
#

class Account < ActiveRecord::Base
  attr_protected :direct_login, :owner_id, :is_blocked, :is_active, :bank_account, :referer, :landing_page
  
  belongs_to :owner, :class_name => 'User', :foreign_key => :owner_id
  
  # The address is the one in fiscal_data, there was a time where we wanted
  # to have the separate, but after that we simplified this assumption and
  # the fiscal data for *our* invoices to the user is assumed to be the same
  # fiscal date he uses in the application
  #
  # has_one :address, :as => :addressable, :dependent => :destroy
  has_one :fiscal_data, :dependent => :destroy

  has_many :users, :dependent => :destroy
  has_many :customers, :order => 'name_for_sorting ASC', :dependent => :destroy
  has_many :invoices, :dependent => :destroy

  has_one :login_token_for_agencies, :dependent => :destroy
  after_create :renew_login_token_for_agencies
  
  has_one :chpass_token, :dependent => :destroy

  add_for_sorting_to :name
  
  validates_presence_of   :name
  validates_presence_of   :short_name
  validates_uniqueness_of :short_name
  validates_exclusion_of  :short_name, :in => CONFIG['reserved_subdomains'], :message => 'esta es una dirección reservada'
  validates_format_of     :short_name, :with => %r{\A[a-z][\-a-z\d]+\z}, :message => 'la dirección debe empezar por una letra y sólo puede tener caracteres alfanumericos'
  
  # We do not validate the existence of the owner because of the
  # chicken and egg problem in the public signup, that action
  # must ensure there's a owner.
  validates_associated :owner

  delegate :logo,           :to => :fiscal_data
  delegate :cif,            :to => :fiscal_data
  delegate :iva_percent,    :to => :fiscal_data
  delegate :irpf_percent,   :to => :fiscal_data
  delegate :charges_irpf?,  :to => :fiscal_data
  delegate :invoice_footer, :to => :fiscal_data
  delegate :address,        :to => :fiscal_data

  # Returns the most recent date with an invoice. We do not refer in the name of
  # the method to the "last invoice" because we are ordering invoices around based
  # just on their number. That ordering will in general give the same date, but
  # that assumes numbering and dates are going upwards in parallel. So here we
  # work specifically on invoice dates, since the query is quite well-defined
  # in terms of dates and we can return an answer that is guaranteed to be correct.
  #
  # Additionally, the query is more efficient than going through invoice ordering.
  def maximum_invoice_date
    invoices.maximum(:date)
  end

  def last_invoice
    last_invoices(1).first
  end
  
  def last_invoices(n)
    invoices.sort.slice(0, n)
  end
  
  def not_yet_paid_amount
    Invoice.sum('total', :conditions => {:paid => false, :account_id => id})
  end
  
  def renew_login_token_for_agencies
    # We loop because of the UNIQUE constraint on the token column.
    loop do
      token = FacturagemUtils.random_login_token
      if login_token_for_agencies.nil?
        break if create_login_token_for_agencies(:token => token)
      else
        break if login_token_for_agencies.update_attribute(:token, token)
      end
    end
  end

  def set_chpass_token
    # We loop because of the UNIQUE constraint on the token column.
    loop do
      token = FacturagemUtils.random_chpass_token
      if chpass_token.nil?
        break if create_chpass_token(:token => token)
      else
        break if chpass_token.update_attribute(:token, token)
      end
    end
  end
  
  def has_logo?
    fiscal_data && fiscal_data.logo
  end
end
