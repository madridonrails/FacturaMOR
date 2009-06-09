# == Schema Information
# Schema version: 7
#
# Table name: users
#
#  id                        :integer(11)   not null, primary key
#  account_id                :integer(11)   not null
#  first_name                :string(255)   
#  first_name_for_sorting    :string(255)   
#  last_name                 :string(255)   
#  last_name_for_sorting     :string(255)   
#  created_at                :datetime      
#  updated_at                :datetime      
#  email                     :string(255)   
#  crypted_password          :string(40)    
#  salt                      :string(40)    
#  remember_token            :string(255)   
#  remember_token_expires_at :datetime      
#  activation_code           :string(40)    
#  activated_at              :datetime      
#  is_blocked                :boolean(1)    
#  last_seen_at              :datetime      
#

require 'digest/sha1'
class User < ActiveRecord::Base
  belongs_to :account
  
  add_for_sorting_to :first_name, :last_name
  
  def fullname
    [first_name, last_name].reject { |x| x.blank? }.join(' ')
  end

  #### ----------------------------------------- ####
  ##                                               ##
  #                                                 #
  #     acts_as_authenticated stuff follows         #
  #                                                 #
  ##                                               ##
  #### ----------------------------------------- ####
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :email
  validates_presence_of     :email_confirmation
  validates_confirmation_of :email
  validates_uniqueness_of   :email, :scope => 'account_id'

  validates_length_of       :password, :within => 4..40, :if => :password_required?, :too_short => 'la contraseña es demasiado corta (mínimo %d carateres)', :too_long => '^La contraseña es demasiado larga (máximo %d carateres)'
  validates_confirmation_of :password,                   :if => :password_required?, :message => 'la contraseña y su confirmación no coinciden'

  before_save :encrypt_password

  def after_find
    self.email_confirmation = email
  end

  # Authenticates a user by their email name and unencrypted password, scoped to @current_account.
  # Returns the user or nil.
  def self.authenticate(current_account, email, password)
    u = current_account.users.find_by_email(email) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      #crypted_password.blank? || !password.blank?
      crypted_password.blank? || !password.nil?
    end
end
