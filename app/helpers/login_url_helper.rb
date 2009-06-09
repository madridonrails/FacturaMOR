module LoginUrlHelper
  def login_url_for_agencies
    url_for :controller => 'account', :action => 'login', :login_token => @current_account.login_token_for_agencies.token, :only_path => false
  end
  
  def login_url_for_customer(customer)
    url_for :controller => 'account', :action => 'login', :login_token => customer.login_token.token, :only_path => false
  end
end