class FdataController < ApplicationController
  include LoginUrlHelper # needed to process ERB templates with mail parts
  
  before_filter :ensure_can_write
  
  skip_before_filter :ensure_we_have_fiscal_data, :only => :new
  before_filter :find_fiscal_data, :except => :new
  
  def index
    redirect_to :action => 'show'
  end
  
  def new
    if @current_account.fiscal_data
      redirect_to :action => 'edit'
      return
    end
    if request.get?
      @fiscal_data = FiscalData.new
      @fiscal_data.name = @current_account.name
      @fiscal_data.account = @current_account
      @fiscal_data.iva_percent = 16
    else
      @fiscal_data = FiscalData.new(params[:fiscal_data])
      @fiscal_data.account = @current_account
      @fiscal_data.build_address(params[:address])
      @fiscal_data.build_logo(params[:logo]) unless params[:logo][:uploaded_data].size.zero?
      redirect_to :controller => 'invoices', :action => 'new' if @fiscal_data.save
    end
  end

  def show
    @subject = ERB.new(CONFIG['agencies_login_url_mail_subject']).result(binding)
    @body    = ERB.new(CONFIG['agencies_login_url_mail_body']).result(binding)
  end
  
  def edit
    @wrong_password = @show_email_confirmation = false
    return if request.get?
    
    params[:fiscal_data].delete(:charge_irpf) unless @fiscal_data.account.invoices.empty?

    # Do this before attempt to change email below.
    unless User.authenticate(@current_account, @current_account.owner.email, params[:current_password])
      @wrong_password = true
    end
    
    unless @fiscal_data.account.owner.email == params[:owner][:email] && params[:owner][:email] == params[:owner][:email_confirmation]
      @show_email_confirmation = true
    end
    
    @fiscal_data.attributes = params[:fiscal_data]
    @fiscal_data.account.owner.attributes = params[:owner]
    @fiscal_data.address.attributes = params[:address]

    # If a new logo is uploaded we need to associate a brand new
    # object to fiscal_data instead of updating the current logo,
    # because that one may be linked to existing invoices.
    @fiscal_data.build_logo(params[:logo]) unless params[:logo][:uploaded_data].size.zero?
    
    if @fiscal_data.valid? && !@wrong_password # run validations even if the password was not correct
      FiscalData.transaction do
        @fiscal_data.save!
        @fiscal_data.account.owner.save!
        @fiscal_data.address.save!
        @current_account.renew_login_token_for_agencies if params[:change_login_url_for_agencies] == '1'
        redirect_to :action => 'show'
      end rescue nil
    end
  end
  
  def logo
    if @fiscal_data.logo
      send_data(
        @fiscal_data.logo.image_data(:web),
        :filename => @fiscal_data.logo.filename,
        :disposition => 'inline'
      )
    else
      render :nothing
    end
  end
  
  def find_fiscal_data
    @fiscal_data = @current_account.fiscal_data
  end
  private :find_fiscal_data

  #this_controller_only_responds_to_https
end
