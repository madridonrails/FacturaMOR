require File.dirname(__FILE__) + '/../test_helper'
require 'invoices_controller'

# Re-raise errors caught by the controller.
class InvoicesController; def rescue_action(e) raise e end; end

class InvoicesControllerTest < Test::Unit::TestCase
  fixtures :countries, :accounts, :users, :chpass_tokens, :customers, :login_tokens, :fiscal_datas, :invoices, :invoice_lines, :addresses

  NEW_INVOICE = {:number => '2009_1111', :date => Time.now.to_s(:db),
                 :customer_id => 1, :discount_percent => 2, 
                 :iva_percent => 16, :footer => 'test' }
  REDIRECT_TO_MAIN = {:action => 'list'} # put hash or string redirection that you normally expect

  def setup
    @controller = InvoicesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first = Invoice.find(:first)                
    @request.user_agent = 'Firefox'
    @request.host = "quentin.#{DOMAIN_NAME}"
    login_as :quentin
  end

  def test_index
    get :index
    assert_response :redirect
    assert_redirected_to 'invoices/new'
  end
  
  def test_list
    get :list
    assert_response :success
    assert_template 'list'    
    invoices = check_attrs(%w(invoices))
    assert_equal Invoice.find(:all).length, invoices.length, "Incorrect number of invoices shown"
  end
  
  def test_new
    get :new
    assert_response :success
    assert_template 'new'
  end
  
  def test_create
    invoice_count = Invoice.find(:all).length
    post :create, {:invoice => NEW_INVOICE, :guessed_number => '2009_1111', :amount => '1.0', 
      :description => 'test', :price => '2000.0'}    
    invoice = check_attrs(%w(invoice))
    assert_response :redirect
    assert_redirected_to 'invoices/show'
    assert_equal invoice_count + 1, Invoice.find(:all).length, "Expected an additional Invoice"
  end
  
  def test_edit_with_get
    get :edit, :id => '2009_0001'
    assert_response :success
    assert_template 'edit'
  end
  
  def test_edit_with_post
    changed_invoice = NEW_INVOICE.merge({:number => '2009_0001',:date => Time.now.to_s(:db)})
    post :edit, {:id => '2009_0001', :invoice => changed_invoice}
    invoice = check_attrs(%w(invoice))
    invoice.reload
    changed_invoice.each do |attr_name|
      assert_equal changed_invoice[attr_name], invoice.attributes[attr_name], "@invoice.#{attr_name.to_s} incorrect"
    end
    assert_response :redirect
    assert_redirected_to "invoices/show"
  end
   
  def test_destroy
    invoice_count = Invoice.find(:all).length
    @request.env["HTTP_REFERER"] = '/invoices/list'
    post :destroy, {:id => @first.url_id}
    assert_response :redirect
    assert_equal invoice_count - 1, Invoice.find(:all).length, "Number of Invoices should be one less"
    assert_redirected_to REDIRECT_TO_MAIN
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
