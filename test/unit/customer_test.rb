require File.dirname(__FILE__) + '/../test_helper'

class CustomerTest < Test::Unit::TestCase
  fixtures :accounts, :users, :chpass_tokens, :customers, :countries, :invoices, :invoice_lines, :addresses

  NEW_CUSTOMER = {:name => 'Test Customer'}
  REQ_ATTR_NAMES = %w(name) # name of fields that must be present, e.g. %(name description)
  DUPLICATE_ATTR_NAMES = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)
  ASSOCIATED_ATTR_NAMES = %w(address) # name of fields that must be a valid object if exists
  
  def setup
    # Retrieve fixtures via their name
    # @first = customers(:first)
  end

  def test_raw_validation
    customer = Customer.new
    if REQ_ATTR_NAMES.blank?
      assert customer.valid?, "Customer should be valid without initialisation parameters"
    else
      # If Customer has validation, then use the following:
      assert !customer.valid?, "Customer should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert customer.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

  def test_new
    customer = Customer.new(NEW_CUSTOMER)
    assert customer.valid?, "Customer should be valid"
    NEW_CUSTOMER.each do |attr_name|
      assert_equal NEW_CUSTOMER[attr_name], customer.attributes[attr_name], "Customer.@#{attr_name.to_s} incorrect"
    end
  end

  def test_validates_presence_of
    REQ_ATTR_NAMES.each do |attr_name|
      tmp_customer = NEW_CUSTOMER.clone
      tmp_customer.delete attr_name.to_sym
      customer = Customer.new(tmp_customer)
      assert !customer.valid?, "Customer should be invalid, as @#{attr_name} is invalid"
      assert customer.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end
  
  def test_validates_associated
    customer = customers(:cliente)
    ASSOCIATED_ATTR_NAMES.each do |attr_name|
      associated_info = customer.send(attr_name)
      assert associated_info.valid?, "Associated info @#{attr_name} should be valid" if associated_info
    end
  end

  def test_duplicate
    current_customer = Customer.find(:first)
    DUPLICATE_ATTR_NAMES.each do |attr_name|
      customer = Customer.new(NEW_CUSTOMER.merge(attr_name.to_sym => current_customer[attr_name]))
      assert !customer.valid?, "Customer should be invalid, as @#{attr_name} is a duplicate"
      assert customer.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end
end

