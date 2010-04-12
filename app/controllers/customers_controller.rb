class CustomersController < ApplicationController
  include LoginUrlHelper

  before_filter :ensure_can_write, :except => [:index, :list, :show]
  before_filter :ensure_can_read_all, :only => [:index, :list]
  before_filter :find_customer, :except => [:list, :new, :create_for_invoice, :export_clientes]

  def index
    redirect_to :action => 'list'
  end

  def export_clientes
    return if request.get?

    customers = @current_account.customers

    # These charsets are expected to be common in our users.
    charset = (request_from_a_mac? ? "MAC" : "ISO-8859-1")
    norm = lambda {|str| Iconv.conv("#{charset}//IGNORE", "UTF-8", str)}

    col_sep = (request_from_windows? ? "," : ';')     # Excel understands this one automatically
    row_sep = (request_from_windows? ? "\r\n" : "\n") # in case people treat it as a text file

    csv_string = FasterCSV.generate(:col_sep => col_sep, :row_sep => row_sep) do |csv|
      header  = %w(Numero Nombre CIF Calle1 Calle2 Ciudad Provincia CP Pais notas Descuento%)
      csv << header.map {|h| norm.call(h)}

      customers.each do |i|
        row  = [i.id]
        row += [norm.call(i.name)]
        row += [i.cif]
        row += [i.address.street1]
        row += [i.address.street2]
        row += [i.address.city]
        row += [i.address.province]
        row += [i.address.postal_code]
        row += [i.address.country.name]
        row += [norm.call(i.notes)]
        row += [commify(i.discount_percent)]
        csv << row
      end
    end

    send_data(csv_string, :type => "text/csv; charset=#{charset}", :filename => "export_clientes.csv")
  end

  # Customers listing.
  def list
    @current_order_by  = order_by(1, 0)
    @current_direction = direction()
    page_params = [
      { :order => "name_for_sorting #@current_direction" }
    ]
    @customer_pages, @customers = paginate(
      :customers, {
        :per_page   => CONFIG['pagination_window'],
        :conditions => "account_id = #{@current_account.id}"
      }.merge(page_params[@current_order_by])
    )
    render :partial => 'list' if request.xhr?
  end

  # Customer details.
  def show
    return logout unless can_read_customer?(@customer)
    @subject = ERB.new(CONFIG['customer_login_url_mail_subject']).result(binding)
    @body    = ERB.new(CONFIG['customer_login_url_mail_body']).result(binding)
  end

  # This is the action that gets called from the redbox in the
  # invoice form.
  def create_for_invoice
    @customer = @current_account.customers.build(params[:customer])
    @customer.build_address(params[:address])
    if @customer.save
      # To display this customer on the left header reusing partials.
      @invoice = Invoice.new
      @invoice.customer = @customer
    end
  end
  xhr_only :create_for_invoice

  # Customer creation, GET and POST. Note that customer creation from
  # the invoice redbox is handled by create_for_invoice.
  def new
    if request.get?
      @customer = @current_account.customers.build
    else
      @customer = @current_account.customers.build(params[:customer])
      @customer.build_address(params[:address])
      redirect_to :action => 'list' if @customer.save
    end
  end

  # Customer edition, GET and POST.
  def edit
    return if request.get?
    @customer.attributes = params[:customer]
    @customer.address.attributes = params[:address]
    Customer.transaction do
      @customer.save!
      @customer.address.save!
      @customer.renew_login_token if params[:change_login_url_for_customer] == '1'
      redirect_to :action => 'show', :id => @customer
    end rescue nil
  end

  def destroy
    if request.post? && @customer.can_be_destroyed?
      @customer.destroy
      redirect_to :action => 'list'
    else
      redirect_to :action => 'show', :id => @customer
    end
  end

  def find_customer
    customer = nil
    unless params[:id].blank?
      customer = @current_account.customers.find_by_url_id(params[:id])
    end
    if customer.nil?
      redirect_to :action => 'list'
      return false
    end
    @customer = customer
  end
  protected :find_customer

  #this_controller_only_responds_to_https
end
