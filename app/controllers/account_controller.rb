class AccountController < ApplicationController
  include LoginUrlHelper
  include SecureActions
  
  skip_before_filter :find_user_or_guest, :except => :logout
  skip_before_filter :ensure_we_have_fiscal_data
  
  def login
    if params[:login_token]
      reset_session
      login_token = LoginToken.find_by_token(params[:login_token])
      if login_token
        begin
          if login_token.is_a?(LoginTokenForAgencies) && login_token.account == @current_account
            session[:guest] = {
              :account  => @current_account.id,
              :customer => nil
            }
            redirect_to :controller => 'invoices', :action => 'list'
          elsif login_token.is_a?(LoginTokenForCustomer) && login_token.customer.account == @current_account
            session[:guest] = {
              :account  => @current_account.id,
              :customer => login_token.customer.id
            }
            redirect_to :controller => 'invoices', :action => 'of', :id => login_token.customer
          else
            logout
          end
        rescue
          logout
        end
      else
        logout
      end
    else
      if request.get?
        render :action => 'login', :layout => 'public'
      else
        reset_session
        self.current_user = User.authenticate(@current_account, params[:login], params[:password])
        if logged_in?
          redirect_back_or_default(:controller => 'invoices', :action => 'new')
        else
          flash.now[:notice] = "Por favor revise los datos de acceso."
          render :action => 'login', :layout => 'public'
        end
      end
    end
  end
  
  def send_chpass_instructions
    begin
      @current_account.set_chpass_token
      url_for_chpass = url_for :action => 'chpass', :chpass_token => @current_account.chpass_token.token
      Mailer.deliver_chpass_instructions(@current_account, url_for_chpass)
      flash[:notice] = 'Se ha enviado un email con instrucciones a la dirección de contacto.'
      logger.info("Se ha enviado un chpass mail para #{@current_account.short_name}, con mail de contacto #{@current_account.owner.email}")
    rescue Exception => e
      flash[:notice] = 'Lo sentimos, debido a un problema técnico no ha sido posible enviar el mail, trataremos de solventarlo lo antes posible.'
      logger.error("No se pudo enviar el chpass mail para #{@current_account.short_name}, con mail de contacto #{@current_account.owner.email}")
      logger.error("Motivo: #{e}")
    end
    # This action HAS to be secure, because when you go from a secure action
    # to a non-secure action clients SHOULD not put a referer. And in fact,
    # they don't :-).
    #
    # See http://www.w3.org/2001/tag/doc/whenToUseGet.html.
    redirect_to :back
  end

  def chpass
    @chpass_token = params[:chpass_token]
    if @chpass_token.blank? || @current_account.chpass_token.nil? || @current_account.chpass_token.token != @chpass_token
      logger.warn("invalid chpass request")
      redirect_to :action => 'login'
      return
    end
    @user = @current_account.owner
    if request.post?
      @user.password              = params[:password]
      @user.password_confirmation = params[:password_confirmation]
      if @user.validate_attributes_and_save(:only => [:password, :password_confirmation])
        # chpass tokens are one shot for security reasons
        if not @current_account.chpass_token.destroy
          # Race conditions are very unlikely here, I think the only possible way to enter
          # here is that the database has a problem, we cannot do too much in that case.
          logger.error("I couldn't destroy the chpass token '#{@chpass_token}' of #{@current_account}")
        end
        # log the user in automatically
        self.current_user = User.authenticate(@current_account, @user.email, @user.password)
        redirect_to "/"
        return
      end
    end
    render :action => 'chpass', :layout => 'public'
  end  

  #this_controller_only_responds_to_https
end
