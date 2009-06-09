require 'digest/sha1'

module ApplicationHelper
  include FormatterHelper
  include LoginUrlHelper
  
  # Returns a country selector for the given model attribute, which typically
  # will be called "country_id". If the model has no contry selected Spain is
  # preselected. We cache the country table in order and the Spain country to
  # speed this up.
  @@country_choices = Country.find(:all, :order => 'name_for_sorting ASC').map {|c| [c.name, c.id]} rescue nil
  @@spain_id        = Country.find_by_name_for_sorting('espana').id rescue Country.find_by_name_for_sorting('espana')[:id] rescue nil
  def country_selector(object, method, options = {}, html_options = {})
    real_object = instance_variable_get("@#{object}")
    options = {:selected => @@spain_id}.merge(options) unless real_object.send(method)
    select object, method, @@country_choices, options, html_options
  end
  
  # The application logo as an image tag.
  def facturagem_logo
    image_tag 'logo.png', :alt => "#{APP_NAME}: facturación fácil", :title => "#{APP_NAME}: facturación fácil"
  end
  
  # Returns the logo of the application already linked to the (public) home.
  def facturagem_logo_linked_to_home
    link_to facturagem_logo, "http://www.#{account_domain}"
  end

  # Based on http://labnol.blogspot.com/2006/08/how-to-embed-flv-flash-videos-in-your.html.
  # We use the same stuff but put the player and the skin in our tree to avoid generating
  # traffic in the website pointed by the blog entry.
  def video_object_tag(filename, width, height, options={})
    options = {:auto_play => true}.merge(options)
    url = CGI.escape("http://aspgems.s3.amazonaws.com/facturagem/videos/#{filename}")
    return <<-HTML
      <object width="#{width}" height="#{height}" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=7,0,19,0">
        <param name="salign" value="lt">
        <param name="quality" value="high">
        <param name="scale" value="noscale">
        <param name="wmode" value="transparent"> 
        <param name="movie" value="/flash/flvplay.swf">
        <param name="FlashVars" value="&amp;streamName=#{h(url)}&amp;skinName=/flash/flvskin&amp;autoPlay=true&amp;autoRewind=false">
        <embed width="#{width}" height="#{height}" 
          flashvars="&amp;streamName=#{h(url)}&amp;autoPlay=#{options[:auto_play]}&amp;autoRewind=false&amp;skinName=/flash/flvskin"
          quality="high"
          scale="noscale"
          salign="LT"
          type="application/x-shockwave-flash"
          pluginspage="http://www.macromedia.com/go/getflashplayer"
          src="/flash/flvplay.swf"
          wmode="transparent">
        </embed>
      </object>
    HTML
  end
  
  # If the current account has a logo it returns an image tag that points
  # to the action that serves it. Otherwise returns the empty string.
  def account_logo
    # We use tag() because image_tag() adds ".png" to the URL
    @current_account.has_logo? ? tag('img', :src => url_for(:controller => 'fdata', :action => 'logo'), :alt => 'logo de la cuenta') : ''
  end

  # If the invoice has a logo it returns an image tag that points
  # to the action that serves it. Otherwise returns the empty string.
  def invoice_logo(invoice)
    # We use tag() because image_tag() adds ".png" to the URL
    invoice.has_logo? ? tag('img', :src => url_for(:controller => 'invoices', :action => 'logo', :id => invoice), :alt => 'logo de la factura') : ''
  end
  
  def date_picker(relative_to)
    return <<-HTML
    <script type="text/javascript" charset="utf-8">
      new DatePicker({relative: '#{relative_to}', language: 'sp'});
    </script>
    HTML
  end

  # Returns the image we use as fake checkbox for marking paid/inpaid invoices.
  def check_box_image(checked, options={})
    source = checked ? 'check_box_checked.png' : 'check_box_unchecked.png'
    image_tag(source, options)
  end
  
  # Encapsulates the paid/unpaid toggler generation. If the current user has write
  # permissions the real toggler is returned, otherwise you get the corresponding
  # fake checkbox image, either checked or unchecked
  def invoice_paid_toggler(invoice)
    options = can_write? ? {:onclick => "new Ajax.Request('/invoices/toggle_paid_status/#{invoice.url_id}', {asynchronous:true, evalScripts:true})"} : {}
    check_box_image(invoice.paid, options)
  end
  
  # This is an ad-hoc autocompleter for the description field in the form that
  # adds a new line to an invoice.
  #
  # It expects the price of the selected line coming in the "price" attribute of
  # the returned LIs. We chose the title here instead of the ID because prices
  # are not valid IDs, and titles are valid attributes of list items that can
  # hold arbitrary text.
  def invoice_new_line_description_auto_completer(tag_options={}, completion_options={})
    completion_options = {
      :url => {
        :controller => 'invoices',
        :action     => 'auto_complete_for_invoice_new_description'
      },
      # we do not need a particular name or id for the price input field, we just
      # assume it is the one below the next table cell, in case we want to use
      # the same autocompleter for line edition
      :after_update_element => <<-JS.gsub(/\s+/, ' ')
        function (e, v) {
            var price = Element.extend(e).up().next('td').down('input');
            price.value = v.getAttribute('price');
            price.select();
        }
      JS
    }.merge(completion_options)
    tag_options[:onkeypress] = "if (navigator.userAgent.indexOf('Safari') != -1) {return event.keyCode == Event.KEY_RETURN ? false : true } else { return true }"
    return <<-HTML
      #{text_field_tag tag_options[:name], "", tag_options}
      #{content_tag("div", "", :id => "#{tag_options[:id]}_auto_complete", :class => "auto_complete")}
      #{auto_complete_field tag_options[:id], completion_options}
    HTML
  end
  
  # Remote method call that recomputes and repaints the invoice. This helper is needed
  # by the invoices and customers controller.
  def recompute
    remote_function(:url  => {:controller => 'invoices', :action => 'repaint'}, :submit => 'invoice-form') + "; return false"
  end
  
  # We need the flag select_current_customer in invoice edition, where it is false.
  def customer_selector(object, method, account, prompt, selected, options={}, html_options={})
    customers = account.customers.map {|c| [c.name, c.id]}
    select object, method, customers, :prompt => prompt, :selected => selected
  end

  # Returns the customer name linked to the customers show view.
  def link_to_customer(customer)
    link_to CGI.escapeHTML(customer.name), :controller => 'customers', :action => 'show', :id => customer
  end

  # Returns the invoice number linked to the invoices show view.
  def link_to_invoice(invoice)
    link_to CGI.escapeHTML(invoice.number), :controller => 'invoices', :action => 'show', :id => invoice
  end
  
  # Returns a link to the action that prepares a new invoice for the given customer.
  def link_to_new_invoice_for(name, customer)
    link_to name, :controller => 'invoices', :action => 'new', :from => 'for', :id => customer
  end

  # Returns a link to the action that prepares a new invoice from a given one.
  def link_to_new_invoice_copying(name, invoice)
    link_to name, :controller => 'invoices', :action => 'new', :from => 'copying', :id => invoice
  end
  
  # Returns a link to the action that destroys an invoice. It includes a confirmation dialog,
  # and uses POST.
  def link_to_destroy_invoice(name, invoice)
    link_to(
      name, 
      {:controller => 'invoices', :action => 'destroy', :id => invoice},
      {:confirm => "Esta acción es irreversible.\n¿Está seguro de que desea borrar esta factura?", :method => :post}
    )
  end
  
  # Auxiliary helper to have a link in the view that shows a message
  # in a JavaScript dialog.
  def not_yet_implemented(name, msg="Not Yet Implemented", options={})
    link_to_function name, "alert('#{escape_javascript(msg)}')", options
  end

  # Returns a link to the previous page according to the browser's history,
  # that's plain-old JavaScript.
  def link_to_back(name)
    %Q{<a href="#" onclick="history.go(-1)">#{ERB::Util.html_escape(name)}</a>}
  end
  
  # If the object has validation errors on method, returns the list of messages.
  # We prepend a BR to each error message and the list is wrapped in a SPAN with
  # class "error" and id "errors_for_object_method". If there's no error message
  # the SPAN is still returned so that it is available to Ajax forms.
  #
  # This helper is thought for displaying error messages below their corresponding
  # fields.
  #
  # The HTML is coupled with the one generated by create_for_invoice.rjs.
  def errors_for_attr(object, method)
    err_list = ''
    err = instance_variable_get("@#{object}").send(:errors).on(method)
    if err
      err = [err] if err.is_a?(String)
      err_list = %Q{<br />#{err.join("<br />")}}
    end
    return %Q(<span id="errors_for_#{object}_#{method}" class="error">#{err_list}</span>)
  end
  
  # Returns a question mark icon with a tooltip attached to it.
  def help(msg)
    tooltip_id = FacturagemUtils.random_hex_string
    tooltip_id = "a#{tooltip_id}" # HTML can't start with a number
    return <<-HTML
    #{image_tag("question_mark.gif", :class => 'question-mark', :title => '', :alt => '', :width => 16, :height => 16, :onmouseover => "TagToTip('#{tooltip_id}')")}
    <span id="#{tooltip_id}" style="display:none">#{msg}</span>
    HTML
  end
  
  # Renders the header of tables for listings, taking into account order and direction.
  # This helper had initially no embedded styles, but some CSS classes where added with
  # the final designs. Does not feel too clean but we will put them here by now.
  def table_header_remote(options)
    options = {
      :non_orderable     => [],
      :current_order_by  => @current_order_by,
      :current_direction => @current_direction
    }.merge(options)
    
    options[:url]    ||= {}
    options[:update] ||= 'list'
    html = '<tr class="table-row-head">'
    options[:labels].each_with_index do |label, c|
      html << '<td class="TextTable13White" nowrap="nowrap">'
      if options[:non_orderable].include?(c)
        html << label
      else
        options[:url][:order_by] = c
        icon = ''
        if c == options[:current_order_by]
          icon = '&nbsp;' + (options[:current_direction] == 'ASC' ? image_tag('ico_arrow_up.png', :height => 11, :width => 11) : image_tag('ico_arrow_down.png', :height => 11, :width => 11))
          options[:url][:direction] = (options[:current_direction] == 'ASC' ? 'DESC' : 'ASC')
        else
          options[:url][:direction] = 'ASC'
        end
        html << link_to_remote(
          "#{label}#{icon}",
          :update  => options[:update],
          :url     => options[:url]
        )
      end
      html << '</td>'
    end
    html << '</tr>'
    html
  end
  
  # Returns the links to pages for paginated listings.
  def pagination_browser(options)
    options[:update] ||= 'list'
    options[:url][:action] ||= @current_action
    options[:success] = 'scroll(0,0)' # scroll to the top of the page
    html = []
    paginator = options[:paginator]
    if paginator.current.number > 1
      options[:url][:page] = paginator.first.number
      html << link_to_remote(
        image_tag("flecha_inicio.gif"),
        options
      )
      options[:url][:page] = paginator.current.number - 1
      html << link_to_remote(
        image_tag("flecha_anterior.gif"),
        options
      )      
    end
    html << "&nbsp;Página #{paginator.current.number} de #{paginator.length}&nbsp;"
    if paginator.current.number < paginator.length
      options[:url][:page] = paginator.current.number + 1
      html << link_to_remote(
        image_tag("flecha_siguiente.gif"),
        options
      )
      options[:url][:page] = paginator.last.number
      html << link_to_remote(
        image_tag("flecha_ultima.gif"),
        options
      )
    end
    html.join("&nbsp;")
  end
  
  # Returns an image tag with a default icon, which is an orange star. We use this while
  # we wait for icons in development, but should have no other occurrence in production.
  def missing_icon
    tooltip_id = FacturagemUtils.random_hex_string
    tooltip_id = "a#{tooltip_id}" # HTML can't start with a number
    return <<-HTML
    #{image_tag("missing-icon.png", :class => 'question-mark', :title => '', :alt => '', :width => 25, :height => 25, :style => 'vertical-align: middle', :onmouseover => "TagToTip('#{tooltip_id}')")}
    <span id="#{tooltip_id}" style="display:none">Icono pendiente</span>
    HTML
  end
  
  def next_month_name
    # Note that Date.today.month is 1-based, so we get the next month in the 0-based array.
    %w(enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre)[Date.today.month % 12]
  end
  
  def colgroup_for_data_tables
    return <<-COLGROUP
    <colgroup>
      <col width="20%" />
      <col width="80%" />
    </colgroup>
    COLGROUP
  end
end
