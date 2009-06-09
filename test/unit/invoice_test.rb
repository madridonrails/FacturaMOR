require File.dirname(__FILE__) + '/../test_helper'

class InvoiceTest < Test::Unit::TestCase
  fixtures :accounts, :users, :chpass_tokens, :customers, :countries, :invoices, :invoice_lines, :addresses
  
  NEW_INVOICE = {:number => "2009_1111", :date => Time.now.to_s(:db),:account_id => 1, :customer_id => 1}	# e.g. {:name => 'Test Invoice', :description => 'Dummy'}
  REQ_ATTR_NAMES = %w(number account_id customer_id) # name of fields that must be present, e.g. %(name description)
  DUPLICATE_ATTR_NAMES = %w(number) # name of fields that cannot be a duplicate, e.g. %(name description)

  def setup
    # Retrieve fixtures via their name
    # @first = invoices(:first)
  end

  def test_raw_validation
    invoice = Invoice.new(:date => NEW_INVOICE[:date] )
    if REQ_ATTR_NAMES.blank?
      assert invoice.valid?, "Invoice should be valid without initialisation parameters"
    else
      # If Invoice has validation, then use the following:
      assert !invoice.valid?, "Invoice should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert invoice.errors.invalid?(attr_name.gsub(/_id$/,'').to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

  def test_new
    invoice = Invoice.new(NEW_INVOICE)
    assert invoice.valid?, invoice.errors.full_messages
    NEW_INVOICE.each do |attr_name|
      assert_equal NEW_INVOICE[attr_name], invoice.attributes[attr_name], "Invoice.@#{attr_name.to_s} incorrect"
    end
  end

  def test_validates_presence_of
    REQ_ATTR_NAMES.each do |attr_name|
      tmp_invoice = NEW_INVOICE.clone
      tmp_invoice.delete attr_name.to_sym
      invoice = Invoice.new(tmp_invoice)
      assert !invoice.valid?, "Invoice should be invalid, as @#{attr_name} is invalid"
      assert invoice.errors.invalid?(attr_name.gsub(/_id$/,'').to_sym), "Should be an error message for :#{attr_name}"
    end
  end

  def test_duplicate
    current_invoice = Invoice.find(:first)
    DUPLICATE_ATTR_NAMES.each do |attr_name|
      invoice = Invoice.new(NEW_INVOICE.merge(attr_name.to_sym => current_invoice[attr_name]))
      assert !invoice.valid?, "Invoice should be invalid, as @#{attr_name} is a duplicate"
      assert invoice.errors.invalid?(attr_name.gsub(/_id$/,'').to_sym), "Should be an error message for :#{attr_name}"
    end
  end
end

