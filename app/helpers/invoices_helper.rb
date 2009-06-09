module InvoicesHelper
  def remove_invoice_line
    link_to_function 'Borrar', 'remove_invoice_line(this)'
  end
  
  def format_address(address)
    [
      address.street,
      "#{address.postal_code} #{address.city}",
      "#{address.province} (#{address.country.name})"
    ].join("<br />")
  end
  
  # This is a helper to DRY the repaint of lines and totals in RJSs, it relies
  # on some instance variables but they are ubiquitous, no problem.
  def repaint(page)
    page.replace_html 'invoice-lines', :partial => 'line', :collection => @invoice.lines, :locals => { :for_edition => true }
    page.replace_html 'invoice-discount', (percent_printable?(@invoice.discount_percent) ? @totals_formatter.call(-@invoice.discount) : '')
    page.replace_html 'invoice-tax_base', @totals_formatter.call((@invoice.tax_base))
    page.replace_html 'invoice-irpf',     @totals_formatter.call((-@invoice.irpf)) if @current_account.charges_irpf?
    page.replace_html 'invoice-iva',      @totals_formatter.call(@invoice.iva)
    page.replace_html 'invoice-total',    @totals_formatter.call(@invoice.total)
  end
  
  def percent_printable?(percent)
    percent.nil? || percent.zero? ? false : true
  end
  
  def table_with_last_invoices(last_invoices)
    table = '<table border="0">'
    last_invoices.each do |i|
      table << '<tr>'
      table << "<td>#{h(i.number)}</td>"
      table << "<td>#{format_date(i.date)}</td>"
      table << "<td>#{h(i.customer_name)}</td>"
      table << '</tr>'
    end
    table << '</table>'
    table
  end
end
