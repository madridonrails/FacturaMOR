require File.dirname(__FILE__) + '/../test_helper'

class AccountTest < Test::Unit::TestCase
  fixtures :accounts, :users, :chpass_tokens, :customers, :countries, :invoices, :invoice_lines, :addresses

  NEW_ACCOUNT = {:name => 'Samuel', :short_name => 'samuel'}
  REQ_ATTR_NAMES = %w(name short_name) # name of fields that must be present, e.g. %(name description)
  DUPLICATE_ATTR_NAMES = %w(short_name) # name of fields that cannot be a duplicate, e.g. %(name description)
  ASSOCIATED_ATTR_NAMES = %w(owner) # name of fields that must be a valid object if exists
  
  def setup
    # Retrieve fixtures via their name
    # @first = accounts(:first)
  end

  def test_raw_validation
    account = Account.new
    if REQ_ATTR_NAMES.blank?
      assert account.valid?, "Account should be valid without initialisation parameters"
    else
      # If Account has validation, then use the following:
      assert !account.valid?, "Account should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert account.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

  def test_new
    account = Account.new(NEW_ACCOUNT)
    assert account.valid?, "Account should be valid"
    NEW_ACCOUNT.each do |attr_name|
      assert_equal NEW_ACCOUNT[attr_name], account.attributes[attr_name], "Account.@#{attr_name.to_s} incorrect"
    end
  end

  def test_validates_presence_of
    REQ_ATTR_NAMES.each do |attr_name|
      tmp_account = NEW_ACCOUNT.clone
      tmp_account.delete attr_name.to_sym
      account = Account.new(tmp_account)
      assert !account.valid?, "Account should be invalid, as @#{attr_name} is invalid"
      assert account.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end
  
  def test_validates_associated
    account = accounts(:quentin)
    ASSOCIATED_ATTR_NAMES.each do |attr_name|
      associated_info = account.send(attr_name)
      assert associated_info.valid?, "Associated info @#{attr_name} should be valid" if associated_info
    end
  end

  def test_duplicate
    current_account = Account.find(:first)
    DUPLICATE_ATTR_NAMES.each do |attr_name|
      account = Account.new(NEW_ACCOUNT.merge(attr_name.to_sym => current_account[attr_name]))
      assert !account.valid?, "Account should be invalid, as @#{attr_name} is a duplicate"
      assert account.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end
  
  def test_exclusion_of_reserved_subdomains
    account = Account.new(:short_name => "www",
      :name => "www",
      :blocked => 0)
    assert !account.save
    assert_equal 'esta es una dirección reservada', account.errors.on(:short_name)    
  end
  
  def test_format_of_short_name
    ok = %w{ samuel fernando maria74 yolanda-1 }
    bad = %w{ Samuel fer_nando 74maria "yol anda" }
    
    ok.each do |name|
      account = Account.new(:short_name => name,
      :name => name,
      :blocked => 0)
      assert account.valid?, account.errors.full_messages
    end
    
    bad.each do |name|
      account = Account.new(:short_name => name,
      :name => name,
      :blocked => 0)
      assert !account.valid?, "saving #{name}"
    end
  end
end

