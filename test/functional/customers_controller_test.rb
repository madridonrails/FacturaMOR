require File.dirname(__FILE__) + '/../test_helper'
require 'customers_controller'

# Re-raise errors caught by the controller.
class CustomersController; def rescue_action(e) raise e end; end

class CustomersControllerTest < Test::Unit::TestCase
  fixtures :countries, :accounts, :users, :chpass_tokens, :customers, :login_tokens, :fiscal_datas, :invoices, :invoice_lines, :addresses

  NEW_CUSTOMER = {:name => 'Test Customer', :cif => 'A08065021'}
  COUNTRY = {:country_id => 71}
  REDIRECT_TO_MAIN = {:action => 'list'} # put hash or string redirection that you normally expect

  def setup
    @controller = CustomersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @first = Customer.find(:first)
    @request.user_agent = 'Firefox'
    @request.host = "quentin.#{DOMAIN_NAME}"
    login_as :quentin
  end
  
  def test_index
    get :index
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
  end
  
  def test_list
    get :list
    assert_response :success
    assert_template 'list'    
    customers = check_attrs(%w(customers))
    assert_equal Customer.find(:all).length, customers.length, "Incorrect number of customers shown"
  end

  def test_new
    customer_count = Customer.find(:all).length
    post :new, {:customer => NEW_CUSTOMER, :address => COUNTRY}
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
    assert_equal customer_count + 1, Customer.find(:all).length, "Expected an additional Customer"
  end
  
  def test_create_for_invoice
    customer_count = Customer.find(:all).length
    xhr :post, :create_for_invoice, {:customer => NEW_CUSTOMER, :address => COUNTRY}
    assert_response :success
    assert_template 'create_for_invoice'
    assert_equal customer_count + 1, Customer.find(:all).length, "Expected an additional Customer"
  end
  
  
  def test_edit
    customer_count = Customer.find(:all).length
    post :edit, {:id => @first.url_id, :customer => @first.attributes.merge(NEW_CUSTOMER), :address => COUNTRY}
    customer = check_attrs(%w(customer))
    customer.reload
    NEW_CUSTOMER.each do |attr_name|
      assert_equal NEW_CUSTOMER[attr_name], customer.attributes[attr_name], "@customer.#{attr_name.to_s} incorrect"
    end
    assert_equal customer_count, Customer.find(:all).length, "Number of Customers should be the same"
    assert_response :redirect
    assert_redirected_to "customers/show/"+customer.url_id
  end

  def test_destroy
    customer_count = Customer.find(:all).length
    post :destroy, {:id => customers(:cliente_especial).url_id}
    assert_response :redirect
    assert_equal customer_count - 1, Customer.find(:all).length, "Number of Customers should be one less"
    assert_redirected_to REDIRECT_TO_MAIN
  end
  
  def test_show
    get :show, {:id => @first.url_id}
    assert_response :success
    assert_template 'show'    
  end

protected
	# Could be put in a Helper library and included at top of test class
  def check_attrs(attr_list)
    attrs = []
    attr_list.each do |attr_sym|
      attr = assigns(attr_sym.to_sym)
      assert_not_nil attr,       "Attribute @#{attr_sym} should not be nil"
      assert !attr.new_record?,  "Should have saved the @#{attr_sym} obj" if attr.class == ActiveRecord
      attrs << attr
    end
    attrs.length > 1 ? attrs : attrs[0]
  end
end
