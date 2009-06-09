require File.dirname(__FILE__) + '/../test_helper'
require 'backoffice_controller'

# Re-raise errors caught by the controller.
class BackofficeController; def rescue_action(e) raise e end; end

class BackofficeControllerTest < Test::Unit::TestCase
  fixtures :accounts, :users, :chpass_tokens, :customers, :login_tokens, :fiscal_datas, :countries, :invoices, :invoice_lines, :addresses
  def setup
    @controller = BackofficeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
