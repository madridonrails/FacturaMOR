require 'test/unit'
require 'rubygems'
require 'fileutils'
require 'action_controller/test_process'
require "#{File.dirname(__FILE__)}/../init"
require "#{File.dirname(__FILE__)}/../lib/secure_actions"
require 'ruby-debug'
Debugger.start

CACHE_DIR = 'test_cache'
FILE_STORE_PATH = File.join(File.dirname(__FILE__), '/../temp/', CACHE_DIR)
ActionController::Base.perform_caching = true
ActionController::Base.page_cache_directory = FILE_STORE_PATH
ActionController::Base.fragment_cache_store = :file_store, FILE_STORE_PATH
ActionController::Base.logger = nil
ActionController::Routing::Routes.reload rescue nil


ENV['ACTIONCONTROLLER_PATH'] = "/Users/ian/rails/somultisite/vendor/rails/actionpack/lib"
begin
  require 'action_controller'
rescue LoadError
  if ENV['ACTIONCONTROLLER_PATH'].nil?
    abort <<MSG
Please set the ACTIONCONTROLLER_PATH environment variable to the directory
containing the action_controller.rb file.
MSG
  else
    $LOAD_PATH.unshift << ENV['ACTIONCONTROLLER_PATH']
    begin
      require 'action_controller'
    rescue LoadError
      abort "ActionController could not be found."
    end
  end
end


class SecureActionsController < ActionController::Base
  include SecureActions
  require_ssl :foo, :bar
  caches_page :homepage, :aboutus
  
  def foo
    render :nothing => true
  end
  
  def bar
    render :nothing => true
  end
  
  def baz
    render :nothing => true
  end
  
  def index
    render :nothing => true
  end
  
  def homepage
    render :text => "this is my homepage"
  end
  
  def aboutus
    render :text => "this is my about us page"
  end
  
  
end

class LoginController < ActionController::Base
  include SecureActions
  require_ssl :secure
  
  def index
    render :nothing => true
  end
  
  def secure
    render :nothing => true
  end  
end

class SecureActionsTest < Test::Unit::TestCase
  Object.const_set :USE_SSL, true
  
  def setup
    @controller = SecureActionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    FileUtils.rm_rf(File.dirname(FILE_STORE_PATH))
    FileUtils.mkdir_p(FILE_STORE_PATH)
  end
  
  def teardown
    FileUtils.rm_rf(File.dirname(FILE_STORE_PATH))
  end
  
  def test_required_without_ssl
    assert_not_equal "on", @request.env["HTTPS"]
    get :foo
    assert_response :redirect
    assert_match %r{^https://}, @response.headers['location']
    get :bar
    assert_response :redirect
    assert_match %r{^https://}, @response.headers['location']
  end
  
  def test_required_with_ssl
    @request.env['HTTPS'] = "on"
    get :foo
    assert_response :success
    get :bar
    assert_response :success
  end
  
  def test_allowed_with_ssl
    @request.env['HTTPS'] = "on"
    get :foo
    assert_response :success
    get :bar
    assert_response :success
    get :index
    assert_response :success
  end
  
  def test_ssl_url
    get :index
    assert_match %r{^https://}, @controller.url_for(:action => "foo")
    assert_match %r{^https://}, @controller.url_for(:action => "bar")
    assert_match %r{^https://}, @controller.url_for(:controller => "secure_actions", :action => "foo")       
  end
  
  def test_non_ssl_url
    get :index
    assert_match %r{^http://}, @controller.url_for(:action => "index")    
  end
  
  def test_ssl_link_generated_across_controllers
    get :index
    assert_match %r{^https://}, @controller.url_for(:controller => "login", :action => "secure")
  end
  
  def test_non_ssl_link_generated_across_controllers
    get :index
    assert_match %r{^http://}, @controller.url_for(:controller => "login", :action => "index")
  end
    
  def test_validity_of_cached_page_path
    @request.host = 'ianwarshak.com'
    get :aboutus
    assert_page_cached :aboutus, "get aboutus should have been cached"    
  end
  
  def test_old_page_caching_would_break_if_not_overwritten
    # Temporarily swap out substitute the cache_page method with old_cache_page
    # to test that the cache methods that come w/Rails would have broken
    
    @controller.class.class_eval { alias_method :good_cache_page, :cache_page }
    @controller.class.class_eval { alias_method :good_expire_page, :expire_page }    
    @controller.class.class_eval { alias_method :cache_page, :old_cache_page }
    @controller.class.class_eval { alias_method :expire_page, :old_expire_page }
    
    get :homepage
    assert_page_not_cached :homepage, "homepage was cached improperly"     
    
    # Put the correct cache method back in place
    @controller.class.class_eval { alias_method :cache_page, :good_cache_page }
    @controller.class.class_eval { alias_method :expire_page, :good_expire_page }
  end
  
  
  
  private
    def assert_page_cached(action, message = "#{action} should have been cached")
      assert page_cached?(action), message
    end

    def assert_page_not_cached(action, message = "#{action} shouldn't have been cached")
      assert !page_cached?(action), message
    end

    def page_cached?(action)
      File.exist? "#{FILE_STORE_PATH}/secure_actions/#{action}.html"
    end
  
    
  
end


