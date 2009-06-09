require File.dirname(__FILE__) + '/../test_helper'
require 'announcement_controller'

# Re-raise errors caught by the controller.
class AnnouncementController; def rescue_action(e) raise e end; end

class AnnouncementControllerTest < Test::Unit::TestCase
  fixtures :accounts, :users, :chpass_tokens, :customers, :login_tokens, :fiscal_datas, :countries, :invoices, :invoice_lines, :addresses
  def setup
    @controller = AnnouncementController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.user_agent = 'Firefox'
    @request.host = "quentin.#{DOMAIN_NAME}"
    login_as :quentin
  end

  def test_hide
    get :hide
    assert session[:hide_announcement]
  end
end
