require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase
  fixtures :accounts, :users, :chpass_tokens, :customers, :login_tokens, :fiscal_datas, :countries, :invoices, :invoice_lines, :addresses

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.user_agent = 'Firefox'
    @request.host = "www.#{DOMAIN_NAME}"
  end

  def test_should_login_and_redirect
    @request.host = "quentin.#{DOMAIN_NAME}"
    post :login, :login => 'quentin@example.com', :password => 'abracadabra'
    assert session[:user]
    assert_response :redirect
  end

  def test_should_fail_login_and_not_redirect
    @request.host = "quentin.#{DOMAIN_NAME}"
    post :login, :login => 'quentin@example.com', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
  end

  def test_should_logout
    @request.host = "quentin.#{DOMAIN_NAME}"
    login_as :quentin
    get :logout
    assert_nil session[:user]
    assert_response :redirect
    assert_redirected_to 'account/login'
  end

	
##  auth_token is no longer used, but in the future ...
#
#  def test_should_remember_me
#    @request.host = "quentin.#{DOMAIN_NAME}"
#    post :login, :login => 'quentin@example.com', :password => 'abracadabra', :remember_me => "1"
#    assert_not_nil @response.cookies["auth_token"]
#  end
#
#  def test_should_not_remember_me
#    @request.host = "quentin.#{DOMAIN_NAME}"
#    post :login, :login => 'quentin@example.com', :password => 'abracadabra', :remember_me => "0"
#    assert_nil @response.cookies["auth_token"]
#  end
#  
#  def test_should_delete_token_on_logout
#    @request.host = "quentin.#{DOMAIN_NAME}"
#    login_as :quentin
#    get :logout
#    assert_equal @response.cookies["auth_token"], []
#  end
#
#  def test_should_login_with_cookie
#    users(:quentin).remember_me
#    @request.cookies["auth_token"] = cookie_for(:quentin)
#    get :index
#    assert @controller.send(:logged_in?)
#  end
#
#  def test_should_fail_expired_cookie_login
#    users(:quentin).remember_me
#    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago
#    @request.cookies["auth_token"] = cookie_for(:quentin)
#    get :index
#    assert !@controller.send(:logged_in?)
#  end
#
#  def test_should_fail_cookie_login
#    users(:quentin).remember_me
#    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
#    get :index
#    assert !@controller.send(:logged_in?)
#  end
#
#  protected
#    def auth_token(token)
#      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
#    end
#    
#    def cookie_for(user)
#      auth_token users(user).remember_token
#    end
end
