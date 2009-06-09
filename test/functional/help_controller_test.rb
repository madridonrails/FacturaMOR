require File.dirname(__FILE__) + '/../test_helper'
require 'help_controller'

# Re-raise errors caught by the controller.
class HelpController; def rescue_action(e) raise e end; end

class HelpControllerTest < Test::Unit::TestCase
  def setup
    @controller = HelpController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.user_agent = 'Firefox'
    @request.host = "www.#{DOMAIN_NAME}"
  end
  
  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end
  def test_about
    get :about
    assert_response :success
    assert_template 'about'
  end  
  def test_general
    get :general
    assert_response :success
    assert_template 'general'
  end  
  def test_howto
    get :howto
    assert_response :success
    assert_template 'howto'
  end  
  def test_invoices
    get :invoices
    assert_response :success
    assert_template 'invoices'
  end 
end
