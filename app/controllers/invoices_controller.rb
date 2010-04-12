require 'set'
require 'fastercsv'
require 'iconv'

class InvoicesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include FormatterHelper
  include InvoicesHelper

  before_filter :ensure_can_write, :except => [:index, :of, :list, :pending, :show, :pdf, :export, :logo]
  before_filter :find_invoice, :only => [:show, :edit, :destroy, :pdf, :toggle_paid_status, :logo, :update_account]

  @@INVOICE_TEMPLATE = File.read(File.join(RAILS_ROOT, 'config', 'invoice.tex.erb'))
  @@INVOICE_DIRECTORY = File.join(RAILS_ROOT, 'tmp', 'latex')

  def index
    action = logged_in_as_guest? ? 'list' : 'new'
    redirect_to :action => action
  end

  def list
    if can_read_all?
      @invoice_pages, @invoices = paginator("invoices.account_id = #{@current_account.id}")
      respond_to do |format|
        format.html { render :action => 'list' }
        format.js   { render :partial => 'list' }
      end
    else
      redirect_to :action => 'of', :id => @guest[:customer]
      return
    end
  end

  def of
    @customer = @current_account.customers.find_by_url_id(params[:id])
    return logout unless can_read_customer?(@customer)
    @invoice_pages, @invoices = paginator("invoices.customer_id = #{@customer.id}")
    respond_to do |format|
      format.html { render :action => 'list' }
      format.js   { render :partial => 'list' }
    end
  end

  def pending
    conditions = can_read_all? ? "invoices.account_id = #{@current_account.id}" : "invoices.customer_id = #{@guest[:customer].id}"
    conditions << " AND paid = 0"
    @invoice_pages, @invoices = paginator(conditions)
    respond_to do |format|
      format.html { render :action => 'list' }
      format.js   { render :partial => 'list' }
    end
  end

  def paginator(conditions)
    @current_order_by  = order_by(5, 1)
    @current_direction = direction('DESC')

    case @current_order_by
    when 0
      is = @current_account.invoices.find(:all, :conditions => conditions)
      is = Invoice.sort_by_number_asc(is)
      is.reverse! if @current_direction == 'DESC'
      paginate_collection(is)
    when 1
      is = @current_account.invoices.find(:all, :conditions => conditions).sort
      is = is.reverse if @current_direction == 'ASC'
      paginate_collection(is)
    else
      page_params = [
        { :order => "invoices.number #@current_direction" },
        { :order => "invoices.date #@current_direction" },
        { :order => "customers.name_for_sorting #@current_direction" },
        { :order => "invoices.total #@current_direction" },
        { :order => "invoices.paid #@current_direction" }
      ]
      paginate(
        :invoices, {
          :include    => [:customer],
          :per_page   => CONFIG['pagination_window'],
          :conditions => conditions
        }.merge(page_params[@current_order_by])
      )
    end
  end
  private :paginator

  def toggle_paid_status
    @invoice.toggle! :paid
    render :partial => 'toggle_paid_status'
  end
  xhr_only :toggle_paid_status

  def show
    return logout unless can_read_customer?(@invoice.customer)
    set_formatters
    nilify_for_view
  end

  def create
    # Compute the current last_invoices in case validation fails,
    # otherwise the one we build is taken into account.
    @last_invoices   = @current_account.last_invoices(5)
    @invoice         = @current_account.invoices.build(params[:invoice])
    @invoice.account = @current_account # to copy all data into the invoice
    @invoice.logo    = @current_account.logo if @current_account.has_logo?
    unless params[:invoice][:customer_id].blank?
      begin
        customer = @current_account.customers.find(params[:invoice][:customer_id])
        @invoice.customer = customer # to copy all data into the invoice
      rescue
        @invoice.customer = nil
      end
    end

    build_body_from_params(true)

    if @invoice.save
      # TODO: This should go in an after filter.
      n = params[:guessed_number]
      if n && @invoice.number != n && @current_account.invoices.size > 1
        last_invoices = @current_account.last_invoices(10).map do |i|
          [i.number, format_date(i.date)].join(' ')
        end.join("\n  ")

        devalert("number guesser mismatch", <<-BODY)
The account #{@current_account.short_name} with id #{@current_account.id} has created an invoice
with number '#{@invoice.number}' but the number guesser suggested '#{n}'.

The last invoices for this account are:

  #{last_invoices}
BODY
      end
      redirect_to :action => 'show', :id => @invoice
    else
      set_formatters
      nilify_for_view
      render :action => 'new'
    end
  end
  verify :only => :create, :method => :post, :redirect_to => {:action => 'new'}

  def new
    @invoice              = Invoice.new # do not build because the next number guesser works on valid invoices
    @invoice.account      = @current_account # do it this way to trigger data copying
    @invoice.number       = Invoice.guess_next_number(@current_account)
    @invoice.date         = Date.today
    @invoice.irpf_percent = @current_account.irpf_percent if @current_account.charges_irpf?
    @invoice.iva_percent  = @current_account.iva_percent
    @invoice.footer       = @current_account.invoice_footer
    @last_invoices        = @current_account.last_invoices(5)
    if params[:from] && params[:id]
      if params[:from] == 'for'
        new_for_customer
      elsif params[:from] == 'copying'
        new_copying_invoice
      end
    end
    set_formatters
    nilify_for_view
  end

  def new_for_customer
    customer = @current_account.customers.find_by_url_id(params[:id])
    if customer
      @invoice.customer = customer
      @invoice.discount_percent = customer.discount_percent
    end
  end
  private :new_for_customer

  def new_copying_invoice
    invoice_to_copy = @current_account.invoices.find_by_url_id(params[:id])
    if invoice_to_copy
      # we need to recopy account and customer in case their data has changed
      @invoice.account          = invoice_to_copy.account
      @invoice.customer         = invoice_to_copy.customer
      # no need to clone because this is only needed to build a new invoice for the view
      invoice_to_copy.lines.each {|line| @invoice.lines << line}
      @invoice.irpf_percent     = invoice_to_copy.irpf_percent if @current_account.charges_irpf?
      @invoice.discount_percent = invoice_to_copy.discount_percent
      @invoice.iva_percent      = invoice_to_copy.iva_percent
      @invoice.compute_totals
      @invoice.footer = invoice_to_copy.footer
    end
  end
  private :new_copying_invoice

  def edit
    @last_invoices = @current_account.last_invoices(5)
    if request.get?
      set_formatters
      nilify_for_view
    else
      begin
        Invoice.transaction do
          @invoice.account = @current_account unless params[:update_account].blank?
          @invoice.logo    = @invoice.account.logo unless params[:update_logo].blank?
          if params[:invoice][:customer_id].blank?
            # a blank means the current customer is OK
            params[:invoice].delete(:customer_id)
          else
            # otherwise we need to reassign, in the case the ID is the same as
            # the ID of the current associated customer that means a reload of
            # its data. That updates the data if the customer's card has been
            # updated after its assignment to this invoice.
            @invoice.customer = @current_account.customers.find(params[:invoice][:customer_id])
          end
          @invoice.attributes = params[:invoice]
          build_body_from_params(true)
          @invoice.save!
          @invoice.pdf.destroy unless @invoice.pdf.nil? # force regeneration of PDF
          redirect_to :action => 'show', :id => @invoice
        end
      rescue
        set_formatters
        nilify_for_view
      end
    end
  end

  def logo
    return logout unless can_read_customer?(@invoice.customer)
    return :nothing unless @invoice.has_logo?
    send_data(
      @invoice.logo.image_data(:web),
      :filename => @invoice.logo.filename,
      :disposition => 'inline'
    )
  end

  def pdf
    return logout unless can_read_customer?(@invoice.customer)
    generate_pdf if @invoice.pdf.nil?
    if @invoice.pdf && @invoice.pdf.data
      send_data(@invoice.pdf.data, :type => "application/pdf", :filename => "factura_#{@current_account.short_name}_#{@invoice.url_id}.pdf")
    else
      render :nothing => true # TODO
    end
  end

  def generate_pdf
    set_formatters(:target => :latex)

    # Prepare the logo. attachment_fu leaves a temporary file, and we perform some
    # conversions in case it is not supported by the graphicx LaTeX package, which is
    # as strict as not accepting JPEGS as files with extension ".jpeg".
    @logo_path = (File.expand_path(@invoice.logo.create_temp_file(:pdf).path) rescue nil)
    @logo_path = fix_logo_for_graphicx(@logo_path) if @logo_path
    latex = ERB.new(@@INVOICE_TEMPLATE, nil, ">").result(binding)
    data = process_latex(latex)
    @invoice.create_pdf(:data => data) if data
  end
  private :generate_pdf

  def fix_logo_for_graphicx(path)
    # Graphicx thinks "39950332sb_competicio.114178-0.jpg" has extension ".114178-0.jpg"
    ext = File.extname(path)
    if path.count('.') > 1
      dirname  = File.dirname(path)
      basename = File.basename(path, ext)
      new_path = File.join(dirname, basename.tr('.', '_') + ext)
      File.rename(path, new_path)
      return fix_logo_for_graphicx(new_path)
    end
    new_path = path

    if !%w(.png .jpg .eps).include?(ext)
      # If we fail here we cannot generate the PDF anyway, so we don't check status codes
      if ext == ".jpeg"
        new_path = path.sub(/\.jpeg$/, ".jpg")
        File.rename(path, new_path)
      else
        new_path = path.sub(/\.\w+$/, ".png")
        system "convert '#{path}' '#{new_path}'" # note these are sanitized paths
      end
    end

    return new_path
  end
  private :fix_logo_for_graphicx

  def process_latex(latex)
    data = nil

    rhs    = FacturagemUtils.random_hex_string
    source = "#{rhs}.tex"
    pdf    = "#{rhs}.pdf"

    # batchmode is important, by default the command waits for input if there's a problem with the PDF.
    # the -option-directory flag is not supported in the production machine
    Dir.chdir(@@INVOICE_DIRECTORY) do
      File.open(source, "w") {|fh| fh.write(latex)}
      success = false
      silence_stream(STDOUT) do
        success = (system("pdflatex -interaction=batchmode #{source}") rescue false)
      end
      if success
        data = File.open(pdf, "rb") {|fh| fh.read} # this is about 24K, depending on the logo
        File.delete("#{rhs}.aux")
        File.delete("#{rhs}.log")
        File.delete("#{rhs}.tex")
        File.delete("#{rhs}.pdf")
      else
        # What can we do here?
      end
    end

    return data
  end
  private :process_latex

  def destroy
    @invoice.destroy
    redirect_to :back
  end
  verify :only => :destroy, :method => :post, :redirect_to => {:action => 'list'}

  def find_invoice
    @invoice = @current_account.invoices.find_by_url_id(params[:id])
    unless @invoice
      redirect_to :action => 'list'
      return false
    end
  end
  private :find_invoice

#  def commify(n)
#    n.to_s.tr('.', ',')
#  end
#  private :commify

  def export
    return if request.get?

    period_conditions = case params[:period]
      when 'current_quarter'
        date_from = Time.now.beginning_of_quarter.to_date
        date_to   = date_from.to_time.months_since(2).end_of_month.to_date
        {:date => date_from..date_to}
      when 'last_quarter'
        date_from = Time.now.months_ago(3).beginning_of_quarter.to_date
        date_to   = date_from.to_time.months_since(2).end_of_month.to_date
        {:date => date_from..date_to}
      when 'current_year'
        {:year => Date.today.year}
      when 'last_year'
        {:year => Date.today.year - 1}
      else
        {}
    end

    customer_conditions = if can_read_all?
      # we do not need to check customer_id against injection because we constrain afterwards
      params[:customer_id].blank? ? {} : {:customer_id => params[:customer_id].to_i}
    else
      {:customer_id => @guest[:customer].id}
    end

    conditions = period_conditions.merge(customer_conditions)
    conditions = nil if conditions.blank? # an empty hash gives invalid SQL
    invoices = @current_account.invoices.find(:all, :conditions => conditions)

    # These charsets are expected to be common in our users.
    charset = (request_from_a_mac? ? "MAC" : "ISO-8859-1")
    norm = lambda {|str| Iconv.conv("#{charset}//IGNORE", "UTF-8", str)}

    col_sep = (request_from_windows? ? "," : ';')     # Excel understands this one automatically
    row_sep = (request_from_windows? ? "\r\n" : "\n") # in case people treat it as a text file

    wants_lines = !params[:detail_level].blank?
    csv_string = FasterCSV.generate(:col_sep => col_sep, :row_sep => row_sep) do |csv|
      header  = %w(Número Fecha Cliente Descuento% Descuento BaseImponible IVA% IVA)
      header += %w(IRPF% IRPF) if @current_account.charges_irpf?
      header += %w(Total Pagada)
      header += %w(Cantidad Concepto Precio TotalLinea) if wants_lines
      csv << header.map {|h| norm.call(h)}

      invoices.sort.each do |i|
        row  = [i.number, format_date(i.date), norm.call(i.customer_name), commify(i.discount_percent), commify(i.discount), commify(i.tax_base), commify(i.iva_percent), commify(i.iva)]
        row += [commify(i.irpf_percent), commify(i.irpf)] if @current_account.charges_irpf?
        row += [commify(i.total), norm.call((i.paid? ? 'Sí' : 'No'))]
        if wants_lines
          i.lines.each do |line|
            csv << row + [commify(line.amount), norm.call(line.description), commify(line.price), commify(line.total)]
          end
        else
          csv << row
        end
      end
    end

    send_data(csv_string, :type => "text/csv; charset=#{charset}", :filename => "export_facturas_#{@current_account.short_name}.csv")
  end


  def export_full
    return if request.get?

    period_conditions = case params[:period]
      when 'current_quarter'
        date_from = Time.now.beginning_of_quarter.to_date
        date_to   = date_from.to_time.months_since(2).end_of_month.to_date
        {:date => date_from..date_to}
      when 'last_quarter'
        date_from = Time.now.months_ago(3).beginning_of_quarter.to_date
        date_to   = date_from.to_time.months_since(2).end_of_month.to_date
        {:date => date_from..date_to}
      when 'current_year'
        {:year => Date.today.year}
      when 'last_year'
        {:year => Date.today.year - 1}
      else
        {}
    end

    customer_conditions = if can_read_all?
      # we do not need to check customer_id against injection because we constrain afterwards
      params[:customer_id].blank? ? {} : {:customer_id => params[:customer_id].to_i}
    else
      {:customer_id => @guest[:customer].id}
    end

    conditions = period_conditions.merge(customer_conditions)
    conditions = nil if conditions.blank? # an empty hash gives invalid SQL
    invoices = @current_account.invoices.find(:all, :conditions => conditions)

    # These charsets are expected to be common in our users.
    charset = (request_from_a_mac? ? "MAC" : "ISO-8859-1")
    norm = lambda {|str| Iconv.conv("#{charset}//IGNORE", "UTF-8", str)}

    col_sep = (request_from_windows? ? "," : ';')     # Excel understands this one automatically
    row_sep = (request_from_windows? ? "\r\n" : "\n") # in case people treat it as a text file

    wants_lines = !params[:detail_level].blank?
    csv_string = FasterCSV.generate(:col_sep => col_sep, :row_sep => row_sep) do |csv|
      header  = %w(Número Fecha NombreEmisor CIFEmisor Calle1Emisor Calle2Emisor CiudadEmisor ProvinciaEmisor CPEmisor PaisEmisor IDCliente NombreCliente CifCliente Calle1Cliente Calle2Cliente CiudadCliente ProvinciaCliente CPCliente PaisCliente notas footer Descuento% Descuento BaseImponible IVA% IVA)
      header += %w(IRPF% IRPF)
      header += %w(Total Pagada)
      header += %w(NºLínea Cantidad Concepto Precio TotalLinea) if wants_lines
      csv << header.map {|h| norm.call(h)}

      invoices.sort.each do |i|        
        row  = [i.number]
        row += [format_date(i.date)]
        row += [norm.call(i.account_name)]
        row += [i.account_cif]
        row += [i.account_street1]
        row += [i.account_street2]
        row += [i.account_city]
        row += [i.account_province]
        row += [i.account_postal_code]
        row += [Country.find_by_id(i.account_country_id).name]
        row += [i.customer_id]
        row += [norm.call(i.customer_name)]
        row += [i.customer_cif]
        row += [i.customer_street1]
        row += [i.customer_street2]
        row += [i.customer_city]
        row += [i.customer_province]
        row += [i.customer_postal_code]
        row += [Country.find_by_id(i.customer_country_id).name]
        row += [norm.call(i.notes)]
        row += [norm.call(i.footer)]
        row += [commify(i.discount_percent)]
        row += [commify(i.discount)]
        row += [commify(i.tax_base), commify(i.iva_percent), commify(i.iva)]
        row += [commify(i.irpf_percent), commify(i.irpf)]
        row += [commify(i.total), norm.call((i.paid? ? 'Sí' : 'No'))]
        if wants_lines
          line_count = 1
          i.lines.each do |line|
            csv << row + [line_count,  commify(line.amount), norm.call(line.description), commify(line.price), commify(line.total)]
            line_count+=1;
          end
        else
          csv << row
        end
      end
    end

    send_data(csv_string, :type => "text/csv; charset=#{charset}", :filename => "export_facturas_#{@current_account.short_name}.csv")
  end

 
  # ---------------------------------------------------- #
  #                                                      #
  #  Remote methods to support invoice creation/edition  #
  #                                                      #
  # ---------------------------------------------------- #

  def parse_decimal(f)
    FacturagemUtils.parse_decimal(f)
  end
  private :parse_decimal

  def update_logo
  end
  xhr_only :update_logo

  def update_account
    @invoice.account = @current_account
  end
  xhr_only :update_logo

  def update_customer
    id = params[:invoice][:customer_id]
    unless id.blank?
      begin
        @customer = @current_account.customers.find(id)
      rescue
        # this is not fatal, perhaps it was deleted in the meantime in another
        # parallel session, perhaps the user is trying to obtain information
        # about customers of other accounts, just let the view handle this case.
        # TODO: possibly rebuild the combo
      end
    end
  end
  xhr_only :update_customer

  def auto_complete_for_invoice_new_description
    description = FacturagemUtils.normalize_for_sorting(params[:new_line_description])
    candidates = InvoiceLine.find(
      :all,
      :include => [:invoice],
      :conditions => [
        "invoices.account_id = ? AND invoice_lines.description_for_sorting LIKE ?",
        @current_account.id,
        "%#{description}%"
      ],
      :order => 'invoices.created_at DESC',
      :limit => 10
    )

    # filter duplicates out
    seen_descriptions = Set.new
    @lines = []
    candidates.each do |c|
      @lines << c unless seen_descriptions.member?(c.description)
      seen_descriptions << c.description
    end

    render :partial => 'auto_complete_for_invoice_new_description'
  end
  xhr_only :auto_complete_for_invoice_new_description

  # The login in this method is tied to the warning in the body editor
  # in the hidden row with id 'new_line_warning'.
  def new_line_can_be_added
    !%w(amount description).any? {|w| params["new_line_#{w}"].blank?}
  end
  private :new_line_can_be_added

  def add_new_line
    if new_line_can_be_added
      @invoice = @current_account.invoices.build(params[:invoice])
      build_body_from_params(true)
      set_formatters
    else
      render :update do |page|
        page.visual_effect :appear, 'new_line_warning', :queue => 'end'
        page.visual_effect :fade, 'new_line_warning', :queue => 'end', :delay => 2.0
      end
    end
  end
  xhr_only :add_new_line

  def edit_line
    @invoice = @current_account.invoices.build(params[:invoice])
    build_lines_from_params(false)
    @line_to_edit = @invoice.lines.delete_at(params[:nline].to_i)
    @invoice.compute_totals
    set_formatters
    render :nothing => true unless @line_to_edit
  end
  xhr_only :edit_line

  def delete_line
    @invoice = @current_account.invoices.build(params[:invoice])
    build_lines_from_params(false)
    @invoice.lines.delete_at(params[:nline].to_i)
    @invoice.compute_totals
    set_formatters
    render :update do |page|
      repaint(page)
    end
  end
  xhr_only :delete_line

  def repaint
    @invoice = @current_account.invoices.build(params[:invoice])
    build_body_from_params
    set_formatters
    render :update do |page|
      repaint(page)
    end
  end
  xhr_only :repaint

  # Builds @invoice.lines from params, including the data from the new line form if needed.
  def build_lines_from_params(include_data_in_new_line_form)
    lines = params[:amount].blank? ? [] : params[:amount].zip(params[:description], params[:price])
    if include_data_in_new_line_form && new_line_can_be_added
      new_line = %w(amount description price).map {|w| params["new_line_#{w}"]}
      new_line[-1] = "0" if new_line[-1].blank? # note that we assume strings in lines
      lines << new_line
    end
    @invoice.lines.clear
    lines.each do |a, d, p|
      a = a.blank? ? nil : parse_decimal(a)
      p = p.blank? ? 0.to_d : parse_decimal(p)
      @invoice.lines.build(
        :amount      => a,
        :description => d,
        :price       => p,
        :total       => (a && p) ? a*p : nil
      )
    end
  end
  private :build_lines_from_params

  # Builds the body of the invoice for the view setting the expected
  # variables taking params as the invoice content.
  def build_body_from_params(include_data_in_new_line_form=false)
    build_lines_from_params(include_data_in_new_line_form)
    @invoice.compute_totals
  end
  private :build_body_from_params

  # Set the formatters Procs for the columns in invoice lines.
  def set_formatters_for_lines(options={})
    @amounts_formatter = lambda {|x| format_integer(x, options)}
    @invoice.lines.map(&:amount).each do |q|
      if !FacturagemUtils.integer?(q)
        @amounts_formatter = lambda {|x| format_decimal(x, options)}
        break
      end
    end

    @prices_formatter = lambda {|x| format_money_as_integer(x, options)}
    @invoice.lines.map(&:price).each do |q|
      if !FacturagemUtils.integer?(q)
        @prices_formatter = lambda {|x| format_money_as_decimal(x, options)}
        break
      end
    end
  end
  private :set_formatters_for_lines

  # Set the formatters Procs for views.
  def set_formatters(options={})
    set_formatters_for_lines(options)
    # By now the totals formatter is always the same.
    @totals_formatter = lambda {|x| format_money_as_decimal(x, options)}
  end
  private :set_formatters

  # There's no way to store BigDecimals as NULLs with AR according to my tests,
  # the problem is that adapters delegate to .to_d, which returns 0 for nil.
  # In the views we want to render 0s as empty strings for these values.
  def nilify_for_view
    [:discount, :irpf, :iva].each do |t|
      p = "#{t}_percent"
      q = @invoice.send(p)
      if q && q.zero?
        @invoice.send("#{t}=", nil)
        @invoice.send("#{p}=", nil)
      end
    end
  end
  private :nilify_for_view

  #this_controller_only_responds_to_https
end
