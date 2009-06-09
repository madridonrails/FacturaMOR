require File.dirname(__FILE__) + '/../test_helper'
require 'fdata_controller'

# Re-raise errors caught by the controller.
class FdataController; def rescue_action(e) raise e end; end

class FdataControllerTest < Test::Unit::TestCase
  fixtures :countries, :accounts, :users, :chpass_tokens, :customers, :login_tokens, :fiscal_datas, :invoices, :invoice_lines, :addresses
  NEW_FISCAL_DATA = {:name => 'aaron', :cif => 'A08065021'}
  
  def setup
    @controller = FdataController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.user_agent = 'Firefox'
    @request.host = "quentin.#{DOMAIN_NAME}"    
    login_as :quentin
  end

  def test_index
    get :index
    assert_response :redirect
    assert_redirected_to 'fdata/show'
  end
    
  def test_show
    get :show
    assert_response :success
    assert_template 'show'
  end
  
  def test_new_user_whith_fdata
    get :new
    assert_response :redirect
    assert_redirected_to 'fdata/edit'
  end
  def test_new_whithout_fdata_get
    @request.host = "aaron.#{DOMAIN_NAME}" 
    login_as :aaron    
    get :new
    assert_response :success
    assert_template 'new'
  end
  def test_new_whithout_fdata_post
    @request.host = "aaron.#{DOMAIN_NAME}" 
    login_as :aaron
    fiscal_data_count = FiscalData.find(:all).length
    post :new, {:fiscal_data => NEW_FISCAL_DATA,:logo => {:uploaded_data => ''}, :address => {:country_id => 71}}   
    assert_response :redirect
    assert_redirected_to 'invoices/new'
    assert_equal fiscal_data_count + 1, FiscalData.find(:all).length, "Expected an additional Fiscal Data"    
  end
  
  def test_edit_whith_get
    get :edit
    assert_response :success
    assert_template 'edit'
  end
  
  def test_edit_with_post
    changed_fiscal_data = NEW_FISCAL_DATA.merge({:name => 'alejandro', :cif => 'E13375076'})
    post :edit, {:fiscal_data => NEW_FISCAL_DATA,
                :logo => {:uploaded_data => ''}, 
                :address => {:country_id => 71},
                :current_password => 'abracadabra',
                :owner => {:email => users(:quentin).email,:email_confirmation => users(:quentin).email}}   
#    fiscal_data = check_attrs(%w(fiscal_data))
#    fiscal_data.reload
#    fiscal_data.each do |attr_name|
#      assert_equal changed_fiscal_data[attr_name], fiscal_data.attributes[attr_name], "@fiscal_data.#{attr_name.to_s} incorrect"
#    end
    assert_response :redirect
    assert_redirected_to 'fdata/show'
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
