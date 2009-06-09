require File.dirname(__FILE__) + '/../test_helper'

class AddressTest < Test::Unit::TestCase
  fixtures :accounts, :users, :chpass_tokens, :customers, :countries, :invoices, :invoice_lines, :addresses

  NEW_ADDRESS = {:country_id => 71, :addressable_id => 1, :addressable_type => 'Customer'}
  REQ_ATTR_NAMES = %w(country_id) # name of fields that must be present, e.g. %(name description)
  
  
  def test_raw_validation
    address = Address.new
    if REQ_ATTR_NAMES.blank?
      assert address.valid?, "Address should be valid without initialisation parameters"
    else
      # If Address has validation, then use the following:
      assert !address.valid?, "Address should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert address.errors.invalid?(attr_name.gsub(/_id$/,'').to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

  def test_new
    address = Address.new(NEW_ADDRESS)
    assert address.valid?, "Address should be valid"
    NEW_ADDRESS.each do |attr_name|
      assert_equal NEW_ADDRESS[attr_name], address.attributes[attr_name], "Address.@#{attr_name.to_s} incorrect"
    end
  end

  def test_validates_presence_of
    REQ_ATTR_NAMES.each do |attr_name|
      tmp_address = NEW_ADDRESS.clone
      tmp_address.delete attr_name.to_sym
      address = Address.new(tmp_address)
      assert !address.valid?, "Address should be invalid, as @#{attr_name} is invalid"
      assert address.errors.invalid?(attr_name.gsub(/_id$/,'').to_sym), "Should be an error message for :#{attr_name}"
    end
  end
end

