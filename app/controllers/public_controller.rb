class PublicController < ApplicationController  
  include SecureActions
#  require_ssl :login, :signup

  before_filter :register_referer_and_landing_page
  
  skip_before_filter :find_account
  skip_before_filter :find_user_or_guest
  skip_before_filter :ensure_we_have_fiscal_data

  def index
  end 

  def login
    if request.post?
      User.find(:all, :conditions => {:email => params[:login]}).each do |u|
        if User.authenticate(u.account, params[:login], params[:password])
          u.account.update_attribute(:direct_login, true)
          # At this point the account is "www", that's why we need to
          # construct the URL taken two pieces.
          protocol = USE_SSL ? 'https' : 'http'
          redirect_to "#{protocol}://#{u.account.short_name}.#{account_domain}"
          return
        end
      end
      flash.now[:notice] = "Por favor revise los datos de acceso."
    end
  end

  def accounts_reminder
    begin
      users = User.find_all_by_email(params[:email])
      unless users.empty?
        urls = users.map {|u| "http://#{u.account.short_name}.#{account_domain}"}
        Mailer.deliver_accounts_reminder(params[:email], urls)
      end
    rescue Exception => e
      # do nothing for the view, just log it, otherwise people may figure out our accounts
      logger.info("accounts reminder raised an exception for email '#{params[:email]}'")
      logger.info(e.backtrace.join("\n"))
    end
    # We interporlate the email here because the view calls h().
    flash[:reminder_sent] = "yes"
    flash[:reminder_email] = params[:email]
    redirect_to :action => 'login'
  end
  verify :only => :accounts_reminder, :method => :post, :redirect_to => {:action => 'index'}

  # We use an explicit account owner because account.owner is only assigned
  # if both objects are valid, and thus we couldn't get to it if validation
  # fails.
  def signup
    @account_domain = account_domain
    if request.get?
      @account = Account.new
      @account_owner = User.new
    else
      if create_account
        clean_tracking_stuff_from_session
        redirect_to "http://#{@account.short_name}.#{account_domain}"
        return
      end
    end
  end
  
  def create_account
    params[:account][:short_name] = FacturagemUtils.normalize_for_url_id(params[:account][:short_name])
    @account = Account.new(params[:account])
    @account_owner = User.new(params[:account_owner])
    @account.users << @account_owner
    
    v1 = @account_owner.valid?
    v2 = @account.valid?
    if v1 && v2 # we do it this way to ensure all validations are run
      @account.referer = session[:referer]
      @account.landing_page = session[:landing_page]
      @account.direct_login = true
      @account.save
      @account_owner.account = @account
      @account.owner = @account_owner
      @account.save
      begin
        Mailer.deliver_welcome(@account, "http://#{@account.short_name}.#{account_domain}")
        devalert("Nueva cuenta", <<-BODY, CONTACT_EMAIL_ACCOUNTS)
Nueva alta en #{APP_NAME}:

  Nombre:  #{@account.name}
  Alias:   #{@account.short_name}
  Email:   #{@account_owner.email}
  Landing: #{@account.landing_page}
  Referer: #{@account.referer}

Esta es el alta número #{Account.count}.
        BODY
      rescue Exception => e
        logger.error(e.inspect)
      end
      return true
    end
    return false
  end
  private :create_account
  
  def terms_of_service
    render :action => 'terms_of_service', :layout => false
  end
  
  # This method is not used currently.
  def suggest_short_name
    suggestion = FacturagemUtils.normalize_for_url_id(params[:name])
    # some from http://www.rmc.es/Scripts/Usr/icorporativa/infosolici.asp?idioma=Espa%F1ol&op=17
    suggestion.sub!(/-s(a|l|rl|c|rc|al|ll|i|icav|ii)$/, '')
    suggestion.gsub!(/\b(.)[^-]*-/, '\1') # in case the name is multi-word we take the first letters of initial words
    while Account.find_by_short_name(suggestion) || CONFIG['reserved_subdomains'].include?(suggestion)
      suggestion.sub!(/(\D)$/, "\\11")
      suggestion.isucc!
    end
    render :update do |page|
      page << "$('account_short_name').value = '#{suggestion}';"
      page << "$('account_short_name').onchange();"
      page << "$('account_owner_email').focus();"
    end
  end
  xhr_only :suggest_short_name
  
  def check_availability_of_short_name
    sn = FacturagemUtils.normalize_for_url_id(params[:short_name])
    available = '<em style="color: #0FC10B">(disponible)<em>'
    if sn.blank? || Account.find_by_short_name(sn) || CONFIG['reserved_subdomains'].include?(sn)
      available = '<span class="error">(no disponible)</span>'
    elsif sn != params[:short_name]
      available = %Q{<em style="color: #0FC10B">(disponible como "#{sn}")<em>}
    end
    render :update do |page|
      page.replace_html 'available', available
    end
  end
  
  # Stores the referer and landing page to register them if there's a signup.
  def register_referer_and_landing_page
    session[:referer]      ||= request.referer
    # In modern Rails this is request.url, but in 1.2.3 it does not exist.
    session[:landing_page] ||= request.protocol + request.host_with_port + request.request_uri
  end
  private :register_referer_and_landing_page

  # Here we clean tracking stuff in case someone comes back and performs a
  # signup again.
  def clean_tracking_stuff_from_session
    [:referer, :landing_page].each do |k|
      session[k] = nil
    end
  end
  private :clean_tracking_stuff_from_session

    #To check Exception Notifier
  def error  
    raise RuntimeError, "Generating an error"  
  end
  
end
