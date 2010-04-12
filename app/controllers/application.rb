class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include AccountLocation
  include ExceptionNotifiable

  before_filter :set_controller_and_action_names
  before_filter :ensure_subdomain
  before_filter :check_access_to_public
  before_filter :find_account
  before_filter :find_user_or_guest
  before_filter :ensure_we_have_fiscal_data
  before_filter :handle_eventual_announcement

  session :session_key => '_facturagem_mor_session_id'

  # Inspired by http://jroller.com/page/obie?entry=wrestling_with_the_bots
  session :off, :if => lambda { |req| robot?(req.user_agent) }
  
  filter_parameter_logging :password

  def self.robot?(ua)
    robot_regexp = %r{
      Baidu        |
      Gigabot      |
      Google       |
      libwww-perl  |
      lwp-trivial  |
      msnbot       |
      SiteUptime   |
      Slurp        |
      WordPress    |
      ZIBB         |
      ZyBorg       |
      Yahoo        |
      Lycos_Spider |
      Infoseek
    }xi
    
    if ua =~ robot_regexp
      logger.info("Request from robot #{ua}.")
      return true
    end
    return false
  end

  def logout
    reset_session
    # We need an explicit :login_token => nil if we come from a login with invalid token,
    # because in that case routes rules make Rails set the login_token back in the URL and
    # that produces infinite recursion.
    if logged_in_as_guest?
      redirect_to_url "http://www.#{account_domain}"
    else
      redirect_to :controller => 'account', :action => 'login', :login_token => nil
    end
    false
  end


  def commify(n)
    n.to_s.tr('.', ',')
  end


  def ensure_can_write
    can_write? ? true : logout
  end
  protected :ensure_can_write
  
  def ensure_can_read_all
    can_read_all? ? true : logout
  end
  protected :ensure_can_read_all

  def set_controller_and_action_names
    @current_action     = action_name
    @current_controller = controller_name
  end
  protected :set_controller_and_action_names
  
  # We need this redirection not only for users, I founded that some bots
  # request public pages to our domain directly. We need to respond
  # with the appropiate redirection so they don't index the error page.
  # They would because the error page is a successful HTTP response.
  def ensure_subdomain
    if account_subdomain.blank?
      redirect_to_url "http://www.#{account_domain}#{request.request_uri}"
      return false
    end
    return true
  end
  
  # Prevents account sites from accessing to the public side. This filter
  # assumes the root page is not under public, which is to be expected, and
  # redirects there if needed. In factura the root page is configured in
  # routes.rb.
  def check_access_to_public
    if controller_name == 'public' && account_subdomain != 'www'
      logger.info("attempt to access to a public action from an account site")
      redirect_to_url account_url(account_subdomain)
      return false
    end
  end

  def find_account
    @current_account = Account.find_by_short_name(account_subdomain)
    if !@current_account || @current_account.blocked?
      logger.info("there's no account with short name #{account_subdomain}, redirecting to the home")
      redirect_to_url "http://www.#{account_domain}"
      return false
    end
  end
  protected :find_account
  
  def find_user_or_guest
    # if the account was just created perform auto-login of the owner
    if @current_account.direct_login?
      @current_account.toggle! :direct_login
      self.current_user = @current_account.owner
      return true
    end
    
    # see if this is a guest request now
    @guest = session[:guest] # let @guess be initialized no matter what
    if @guest
      if @guest[:account] == @current_account.id
        begin
          # Usage of @guest showed it is handy to have the actual objects cached.
          # I don't foresee that in a single request there's a chance for relevant
          # unsynchronizations because not only usage is minimal, but guests can't
          # even modify models.
          logger.info("this is a guest request from #{@guest.inspect}")
          @guest = @guest.dup # we do not want the objects in the session
          @guest[:account]  = @current_account
          @guest[:customer] = @current_account.customers.find(@guest[:customer]) if @guest[:customer]
          return true
        rescue
          logout
          return false
        end
      else
        logout
        return false
      end
    end
        
    login_required
    if logged_in?
      if @current_account == current_user.account
        logger.info("current user is #{current_user.id}, with login '#{current_user.email}', from account '#{@current_account.short_name}'") if logged_in?
        current_user.update_attribute(:last_seen_at, Time.now)
      else
        redirect_to :controller => 'account', :acction => 'login'
        return false
      end
    else
      # login_require already sets a redirect to account/login
      return false
    end
  end
  protected :find_user_or_guest
  
  def ensure_we_have_fiscal_data
    if @current_account.fiscal_data.nil?
      redirect_to :controller => 'fdata', :action => 'new'
      return false
    end
  end
  protected :ensure_we_have_fiscal_data

  # Paginates an existing AR result set, returning the Paginator and collection slice.
  #
  # Based upon:
  # http://www.bigbold.com/snippets/posts/show/389
  #
  def paginate_collection(collection, options = {})
    options[:page] = options[:page] || params[:page] || 1
    default_options = {:per_page => CONFIG['pagination_window'], :page => 1}
    options = default_options.merge(options)
    
    pages = Paginator.new(self, collection.size, options[:per_page], options[:page])
    first = pages.current.offset
    last = [first + options[:per_page], collection.size].min
    slice = collection[first...last]
    return [pages, slice]
  end

  # Robust computation of +order_by+ for column ordering in tables. This
  # method checks +params+ for a <tt>:order_by</tt> key and tries to use
  # that as default value.
  def order_by(ncols, default=0)
    if params[:order_by].blank?
      order_by = default
    else
      begin
        order_by = params[:order_by].to_i
        unless 0 <= order_by && order_by < ncols
          order_by = default
        end
      rescue Exception => e
        logger.error(e)
        order_by = default
      end
    end
    order_by
  end
  protected :order_by

  # Robust computation of +direction+ for column ordering in tables.
  # This method checks +params+ for a <tt>:direction</tt> key and tries
  # to use that as default value.
  def direction(default='ASC')
    if params[:direction].blank?
      direction = default
    else
      direction = params[:direction]
      direction = default unless ['ASC', 'DESC'].include?(direction)
    end
    direction
  end
  protected :direction
  
  def self.xhr_only(method_name)
    verify :xhr => true, :only => method_name, :render => {:nothing => true}
  end
  
  # see http://www.iopus.com/imacros/demo/v6/user-agent.htm
  def request_from_a_mac?
    !request.env['HTTP_USER_AGENT'].downcase.index('macintosh').nil?
  end
  
  # see http://www.iopus.com/imacros/demo/v6/user-agent.htm
  def request_from_windows?
    !request.env['HTTP_USER_AGENT'].downcase.index('windows').nil?
  end
  
  # Send alerts on key events to monitor the health of the application.
  def devalert(subject, body='', extra_to=[])
    Mailer.deliver_devalert("[#{APP_NAME}] #{subject}", body, extra_to) if RAILS_ENV == 'production'
  end
  
  # A controller makes this call to declare all their actions run behind SSL.
  # The call must be put at the bottom of the code, so that the public methods
  # are known and returned by public_instance_methods.
  def self.this_controller_only_responds_to_https
    include SecureActions
    require_ssl(*self.public_instance_methods(false).map(&:to_sym))
  end

  def handle_eventual_announcement
    if !CONFIG['announcement'].blank? && !session[:hide_announcement]
      @announcement = ERB.new(CONFIG['announcement']).result(binding)
    end
  end
end
