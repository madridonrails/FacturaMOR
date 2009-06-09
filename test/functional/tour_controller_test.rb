require File.dirname(__FILE__) + '/../test_helper'
require 'tour_controller'

# Re-raise errors caught by the controller.
class TourController; def rescue_action(e) raise e end; end

class TourControllerTest < Test::Unit::TestCase
  def setup
    @controller = TourController.new
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
  def test_customers
    get :customers
    assert_response :success
    assert_template 'customers'
  end
  def test_for_agencies
    get :for_agencies
    assert_response :success
    assert_template 'for_agencies'
  end
  def test_for_customers
    get :for_customers
    assert_response :success
    assert_template 'for_customers'
  end  
  def test_new_invoice
    get :new_invoice
    assert_response :success
    assert_template 'new_invoice'
  end 
    def test_print
    get :print
    assert_response :success
    assert_template 'print'
  end 
end
