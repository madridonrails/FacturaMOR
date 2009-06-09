require File.dirname(__FILE__) + '/../test_helper'
require 'public_controller'

# Re-raise errors caught by the controller.
class PublicController; def rescue_action(e) raise e end; end

class PublicControllerTest < Test::Unit::TestCase 
  fixtures :countries, :accounts, :users, :chpass_tokens, :customers, :login_tokens, :fiscal_datas, :invoices, :invoice_lines, :addresses

  def setup
    @controller = PublicController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.user_agent = 'Firefox'
    @request.host = "www.#{DOMAIN_NAME}"
  end

  def test_should_allow_signup
    assert_difference User, :count do
      create_user
      assert_response :redirect
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference User, :count do
      create_user({},{:email => nil})
      assert assigns(:account_owner).errors.on(:email)
      assert_response :success
    end
  end    

  def test_should_require_password_on_signup
    assert_no_difference User, :count do
      create_user({},{:password => nil})
      assert assigns(:account_owner).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference User, :count do
      create_user({},{:password_confirmation => 'unknown'})
      assert assigns(:account_owner).errors.on(:password)
      assert_response :success
    end
  end
  
  protected
    def create_user(account_options = {},account_owner_options = {})
      post :signup, :account => {:name => 'foo', :short_name => 'foo'}.merge(account_options), 
      :account_owner => {:email => 'foo@example.com',:email_confirmation => 'foo@example.com',
                         :password => 'abracadabra',:password_confirmation => 'abracadabra'}.merge(account_owner_options), 
      :accept_terms_of_service => 'on'
    end    
end
