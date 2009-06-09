require 'fastercsv'

class BackofficeController < ApplicationController
  include FormatterHelper

  PUBLIC_SINCE = Date.new(2007, 7, 18).to_time

  skip_before_filter :find_account  
  skip_before_filter :find_user_or_guest
  skip_before_filter :ensure_we_have_fiscal_data

  before_filter :ensure_user_is_root, :except => :login

  def login
    if request.post?
      if params[:login] == CONFIG['root_login'] && params[:password] == CONFIG['root_password']
        session[:root] = true
        redirect_to :action => 'index'
        return
      else
        flash.now[:notice] = "Por favor revise los datos de acceso."
      end
    end
    render :action => 'login', :layout => 'public'
  end
  
  def logout
    reset_session
    redirect_to :controller => 'public'
  end
  
  def index
    @naccounts                   = Account.count
    @ninternet_accounts          = Account.count(:conditions => ['created_at >= ?', PUBLIC_SINCE])
    @ninvoices                   = Invoice.count
    @ninvoices_with_pdf          = InvoicePdf.count
    @ncustomers                  = Customer.count
    @most_recent_accounts        = Account.find(:all, :order => 'created_at DESC', :limit => 10)
    @nlast_seen_accounts         = User.count(:conditions => ["last_seen_at > ?", 1.month.ago])
    @nlast_registered_accounts   = Account.count(:conditions => ["created_at > ?", 1.month.ago])
    @naccounts_with_some_invoices = Invoice.connection.select_value(<<-SQL).to_i
      SELECT COUNT(*) FROM (
        SELECT COUNT(id) FROM invoices
        GROUP BY account_id HAVING COUNT(id) >= 10
      ) as invoice_counters_per_account
    SQL
  end
  
  def flat_rate
    @accounts = []
    Account.find_each(:order => 'accounts.created_at DESC') do |account|
      @accounts << account if account.pays_by_bank?
    end
  end
  
  # This method has no interface. We were asked to export accounts as CSV to do
  # some analysis and I programmed it as an action for the same price.
  def export_accounts
    # TODO: THERE'S DUPLICATION FROM InvoicesController in CSV setup.

    # These charsets are expected to be common in our users.
    charset = (request_from_a_mac? ? "MacRoman" : "ISO-8859-1")
    norm = lambda {|o| Iconv.conv("#{charset}//IGNORE", "UTF-8", o.to_s)}
    col_sep = (request_from_windows? ? "," : ';')    # Excel understands this one automatically
    row_sep = (request_from_windows? ? "\r\n" : "\n") # in case people treat it as a text file

    csv_string = FasterCSV.generate(:col_sep => col_sep, :row_sep => row_sep) do |csv|
      csv << %w(Nombre Antiguedad Login Facturas Clientes).map {|h| norm.call(h)}
      # this iterator is provided by pseudo_cursors
      Account.find_each(:include => :owner) do |account|
        csv << [
          account.name,
          format_date(account.created_at.to_date),
          (format_date(account.owner.last_seen_at.to_date) rescue ''),
          account.invoices.count,
          account.customers.count
        ].map {|h| norm.call(h)}
      end
    end
    send_data(csv_string, :type => "text/csv; charset=#{charset}", :filename => "accounts_#{Time.now.strftime("%Y%m%d")}.csv")
  end
  
  def accounts
    @current_order_by  = order_by(8, 4)
    @current_direction = direction('DESC')
    
    page_params = [
      nil, # the fist column has no order
      { :order => "accounts.name_for_sorting #@current_direction, accounts.created_at #@current_direction" },
      { :order => "accounts.created_at #@current_direction" },
      { :order => "accounts.created_at #@current_direction" },
      { :order => "accounts.created_at #@current_direction" },
      { :order => "accounts.created_at #@current_direction" },
      { :order => "users.last_seen_at #@current_direction, accounts.created_at #@current_direction" }
    ]
    
    if @current_order_by < page_params.length && page_params[@current_order_by]
      @account_pages, @accounts = paginate(
        :accounts, {
          :per_page => CONFIG['pagination_window_for_backoffice'],
          :include  => :owner
        }.merge(page_params[@current_order_by])
      )
    else
      select = 'accounts.id, accounts.name, accounts.created_at, accounts.owner_id, accounts.short_name'
      @account_pages = Paginator.new(self, Account.count, CONFIG['pagination_window_for_backoffice'], params[:page])
      
      if @current_order_by == page_params.length # invoices
        @accounts = Account.find_by_sql(<<-SQL)
          SELECT #{select} FROM accounts 
          LEFT OUTER JOIN (
            SELECT account_id, COUNT(id) as ninvoices FROM invoices GROUP BY account_id
          ) as invoice_counters
          ON accounts.id = invoice_counters.account_id
          ORDER BY invoice_counters.ninvoices #{@current_direction}, accounts.created_at #{@current_direction}
          LIMIT #{@account_pages.items_per_page}
          OFFSET #{@account_pages.current.offset}
        SQL
      elsif @current_order_by == page_params.length + 1 # customers
        @accounts = Account.find_by_sql(<<-SQL)
          SELECT #{select} FROM accounts 
          LEFT OUTER JOIN (
            SELECT account_id, COUNT(id) as ncustomers FROM customers GROUP BY account_id
          ) as customer_counters
          ON accounts.id = customer_counters.account_id
          ORDER BY customer_counters.ncustomers #{@current_direction}, accounts.created_at #{@current_direction}
          LIMIT #{@account_pages.items_per_page}
          OFFSET #{@account_pages.current.offset}
        SQL
      end
    end
    render :partial => 'list' if request.xhr?
  end
  
  def ensure_user_is_root
    if session[:root]
      return true
    else
      redirect_to :action => 'login'
      return false
    end
  end
  private :ensure_user_is_root
  
  #this_controller_only_responds_to_https
end
