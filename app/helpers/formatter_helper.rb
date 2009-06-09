module FormatterHelper
  
  # All formatters for numbers accept a couple of options, they are:
  #
  #   :target -> either :html, :latex, or :text
  #   :force_zero -> if true nil is rendered as 0
  #
  DEFAULT_OPTIONS_FOR_NUMBER_FORMATTING = {:target => :html, :force_zero => false}

  # Prepares the number to be properly formatted according to the target output.
  # In particular adjusts the minus sign, which is different from the hyphen in
  # typography. The minus sign is a bit wider, like an en-dash.
  #
  # This is a helper for the formatters themselves, it shouldn't be called by
  # code outside this module.
  def format_number_according_to_target(number_as_string, target)
    case target
    when :html
      # The minus sign has Unicode code point U+2212, but Firefox renders a regular hyphen here.
      number_as_string.sub(/^-/, '&ndash;')
    when :latex
      number_as_string.sub(/^-/, '$-$')
    when :text
      # For text the string itself is OK.
      number_as_string
    else
      if RAILS_ENV == 'production'
        '-' # catchall, just in case
      else
        # This is a bug, complain in we are not in production.
        raise "Unkown number formatting target: #{target}"
      end
    end
  end

  def format_decimal(n, options={})
    options = DEFAULT_OPTIONS_FOR_NUMBER_FORMATTING.merge(options)
    n = 0 if n.nil? && options[:force_zero]
    return '' unless n
    n = FacturagemUtils.parse_decimal(n) if n.is_a?(String)
    number_as_string = number_with_delimiter('%0.2f' % n, '.', ',')
    format_number_according_to_target(number_as_string, options[:target])
  end
  
  def format_integer(n, options={})
    options = DEFAULT_OPTIONS_FOR_NUMBER_FORMATTING.merge(options)
    n = 0 if n.nil? && options[:force_zero]
    return '' unless n
    n = FacturagemUtils.parse_integer(n) if n.is_a?(String)
    number_as_string = number_with_delimiter(n.to_i, '.', ',')
    format_number_according_to_target(number_as_string, options[:target])
  end
  
  def format_money_as_decimal(amount, options={})
    formatted = format_decimal(amount, options)
    formatted.blank? ? '' : "#{formatted} €"
  end  
  
  def format_money_as_integer(amount, options={})
    formatted = format_integer(amount, options)
    formatted.blank? ? '' : "#{formatted} €"
  end
  
  def format_integer_or_decimal(n, options={})
    FacturagemUtils.integer?(n) ? format_integer(n, options) : format_decimal(n, options).sub(/0+$/, '')
  end
  
  # According to http://www.xcastro.com/signos.html there's a space between the number and the sign.
  def format_percent(n, options={})
    n = format_integer_or_decimal(n, options)
    n.blank? ? '' : "#{n} %"
  end
  
  
  #
  # -- Dates --------------------------------------------------------
  #
    
  def format_date_short(date)
    date.strftime("%d/%m/%Y") rescue ''
  end
  alias :format_date :format_date_short
  
  def format_date_long(date)
    day = date.day
    month = %w(enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre)[date.month-1]
    year = date.year
    "#{day} de #{month} de #{year}"
  end
  
  #
  # -- Invoice Footer -----------------------------------------------
  #
  
  def x_simple_format(str)
    simple_format(h(str)).sub(%r{\A<p>}i, '').sub(%r{</p>\z}i, '')
  end
  
end
