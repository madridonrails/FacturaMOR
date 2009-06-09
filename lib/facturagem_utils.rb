require 'iconv'
require 'date'
require 'digest/sha1'
require 'rexml/document'
require 'rexml/streamlistener'

module FacturagemUtils
  def self.normalize_for_sorting(str)
    normalize(str).tr('_/\\', '-')
  end
  
  def self.normalize_for_url_id(str)
    normalize(str).tr(' /\\', '-')
  end
  
  # The trick with iconv does not work in Acens due to the version of the library there.
  def self.normalize(str)
    return '' if str.nil?
    n = str.chars.downcase.strip.to_s
    n.gsub!(/[àáâãäåāă]/,    'a')
    n.gsub!(/æ/,            'ae')
    n.gsub!(/[ďđ]/,          'd')
    n.gsub!(/[çćčĉċ]/,       'c')
    n.gsub!(/[èéêëēęěĕė]/,   'e')
    n.gsub!(/ƒ/,             'f')
    n.gsub!(/[ĝğġģ]/,        'g')
    n.gsub!(/[ĥħ]/,          'h')
    n.gsub!(/[ììíîïīĩĭ]/,    'i')
    n.gsub!(/[įıĳĵ]/,        'j')
    n.gsub!(/[ķĸ]/,          'k')
    n.gsub!(/[łľĺļŀ]/,       'l')
    n.gsub!(/[ñńňņŉŋ]/,      'n')
    n.gsub!(/[òóôõöøōőŏŏ]/,  'o')
    n.gsub!(/œ/,            'oe')
    n.gsub!(/ą/,             'q')
    n.gsub!(/[ŕřŗ]/,         'r')
    n.gsub!(/[śšşŝș]/,       's')
    n.gsub!(/[ťţŧț]/,        't')
    n.gsub!(/[ùúûüūůűŭũų]/,  'u')
    n.gsub!(/ŵ/,             'w')
    n.gsub!(/[ýÿŷ]/,         'y')
    n.gsub!(/[žżź]/,         'z')
    n.gsub!(/\s+/,           ' ')
    n.tr!('^ a-z0-9_/\\-',    '')
    n
  end
  
  def self.random_hex_string
    Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
  end
  
  # We use 63 characters and tokens of length 23, which gives 63**23 possible tokens, that's:
  #
  #   242567514087541147634431480398346066867647 (42 digits)
  #
  # enough to prevent brute-force attacks. The 23 was chosen from the length of the keys
  # used in Google Docs in their URLs for sharing.
  @@token_chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_']
  def self.random_login_token
    token = ''
    23.times { token << @@token_chars[rand(@@token_chars.length)] }
    token
  end
  
  class << self
    alias_method :random_chpass_token, :random_login_token
  end
  
  # Copied from RTex
  BS        =	"\\\\"
  BACKSLASH	=	"#{BS}textbackslash{}"
  HAT       =	"#{BS}textasciicircum{}"
  TILDE     =	"#{BS}textasciitilde{}"
  def self.escape_latex(str)
    str = str.to_s.dup
    str.gsub!(/([{}])/, "#{BS}\\1")
    str.gsub!(/\\/, BACKSLASH)
    str.gsub!(/([_$&%#])/, "#{BS}\\1")
    str.gsub!(/\^^/, HAT) # TODO: this one is OK?
    str.gsub!(/~/, TILDE)
    str
  end

  def self.simple_format_to_latex(str)
    # We need to strip first, because some people put newlines at the beginning
    # that cannot be forced with \newline (it generates a LaTeX error). I guess
    # they want the footer with some blank space around in the web view, so we
    # allow that but remove it for the PDF, which has plenty of space anyway.
    str = str.strip
    str = str ? str.gsub(/\r\n/, "\n").gsub(/\n{3,}/, "\n\n") : ''
    escape_latex(str).gsub(/\n/, "\\newline\n")
  end

  # This method understands dd/mm/yyyy. Returns nil on failure.
  def self.parse_date(str)
    day, month, year = str.split("/")
    begin
     return Date.new(year.to_i, month.to_i, day.to_i)
    rescue
      return nil
    end
  end
  
  def self.parse_integer(i)
    parse_decimal(i).to_i
  end
  
  # Returns a BigDecimal out of the string n, 0.0.to_d on failure.
  def self.parse_decimal(n)
    return 0.0.to_d if n.blank?

    # remove everything that cannot be part of assume number, as currency symbols
    n.gsub!(/[^.,\d]+$/, '')
    
    # if n has no comma just delegate to .to_d
    return n.to_d unless n.index(",")
    
    # if it has a comma, but no dot, assume it is a decimal separator
    return n.sub(',', '.').to_d unless n.index(".")
    
    # if we get here it has both a comma and a dot, strip whitespace
    n = n.strip

    # take sign and delete it, if any
    s = n.first == "-" ? -1 : 1
    n.sub!(/^[-+]/, '')

    # extract and remove the decimal part, which is assumed to be the one
    # after the rightmost separator, no matter whether it is a comma or a dot
    n.sub!(/[.,](\d*)$/, '')
    decimal_part = $1 # perhaps the empty string, no problem

    # in what remains, which is taken as the integer part, any non-digit is
    # simply ignored
    n.gsub!(/\D/, '')

    # done
    return s*("#{n}.#{decimal_part}".to_d)
  end
  
  def self.integer?(n)
    n = FacturagemUtils.parse_decimal(n) if n.is_a?(String)
    return n == n.to_i
  end
  
  # This is regexp based because we control de source code (unless hacking, if the user
  # sends some HTML by hand he might get an ugly PDF, he deserves that in that case).
  def self.fckeditor_html_to_latex(html)
    html = html.gsub(/&nbsp;/, ' ')
    fl = FckeditorListener.new
    REXML::Document.parse_stream(html, fl)
    return fl.latex
  end
  
  # Based on
  #
  #  http://es.wikipedia.org/wiki/Algoritmo_para_obtener_la_letra_del_NIF
  def self.nif?(code)
    return false unless code =~ /\A([0-9]{6,8})([A-Z])\z/
    return 'TRWAGMYFPDXBNJZSQVHLCKE'.at($1.to_i % 23) == $2 # same as NIE
  end
  
  # Based on
  #
  #  http://es.wikipedia.org/wiki/Algoritmo_para_obtener_la_letra_del_NIF
  #  http://es.wikipedia.org/wiki/NIE
  #  http://www.seg-social.es/inicio/?MIval=cw_usr_view_Folder&LANG=1&ID=41237#41241
  def self.nie?(code)
    return false unless code =~ /\AX([0-9]{7,8})([A-Z])\z/
    return 'TRWAGMYFPDXBNJZSQVHLCKE'.at($1.to_i % 23) == $2 # same as NIF
  end
  
  # Based on
  #
  #   http://www.latecladeescape.com/w0/content/view/93/49/
  #   http://www.q3.nu/trucomania/truco.cgi?337&esp
  #
  # This one is tricky and most online code is buggy in corner cases,
  # I've found this validator to be a good help:
  #
  #   http://www.notin.net/portal/herramientas/valida_cif.asp
  def self.cif?(code)
    return false unless code =~ /\A([A-HK-NPQS])([0-9]{7})([A-J0-9])\z/
    letter, digits, control = $1, $2, $3
    digits = digits.split(//).map(&:to_i)
    
    x = 0
    digits.each_with_index {|d, i| x += i.even? ? 2*d % 10 + d/5 : d}
    x = 10 - (x % 10) unless x.zero?
    x = 0 if x == 10 # this is missing in most online examples

    if %w(A B E H).include?(letter)
      x.to_s == control
    elsif %w(K P Q S).include?(letter)
      "JABCDEFGHI".at(x) == control
    else
      x.to_s == control || "JABCDEFGHI".at(x) == control
    end
  end
  
  def self.fiscal_identifier?(code)
    code = code.strip.upcase.gsub(%r{[^0-9A-Z]}, '')
    return nif?(code) || nie?(code) || cif?(code)
  end
  
  # We follow
  #
  #  http://www.euskalgraffiti.com/index.php/archives/2005/02/08/calculo-del-digito-de-control-de-una-cuenta-corriente/
  #
  def self.bank_account?(account_number)
    account_number = account_number.gsub(/\D/, '')
    return false if account_number.length != 20
    bank, office, control, account = break_bank_account_into_parts(account_number)
    bank_office = bank + office
    weights = [1, 2, 4, 8, 5, 10, 9, 7, 3, 6].reverse
    
    n = 0
    weights.zip(bank_office.split(//).map(&:to_i).reverse).each do |w, d|
      break if d.nil?
      n += w*d
    end
    n = 11 - (n % 11)
    n = 0 if n == 11
    n = 1 if n == 10
    return false if n.to_s != control.at(0)
    
    n = 0
    weights.zip(account.split(//).map(&:to_i).reverse).each do |w, d|
      n += w*d
    end
    n = 11 - (n % 11)
    n = 0 if n == 11
    n = 1 if n == 10
    return false if n.to_s != control.at(1)
    
    return true
  end
  
  def self.break_bank_account_into_parts(bank_account)
    bank_account.gsub(/\D/, '').unpack('a4a4a2a10')
  end
  
  def self.ip_belongs_to_trivium(ip)
    ip =~ /\A(?:62\.37\.232\.\d+|85\.158\.168\.\d+)\z/;
  end
end

__END__


class FckeditorListener
  include REXML::StreamListener
  
  attr_accessor :stack
  attr_accessor :latex
  attr_accessor :needs_hfill
  
  def initialize
    @stack = []
    @latex = ''
    @needs_hfill = false
  end
  
  def tag_start(name, attrs)
    case name
    when 'div'
      self.needs_hfill = false
      case attrs['align']
      when 'left'
        env = 'flushleft'
      when 'center'
        env = 'center'
      when 'right'
        env = 'flushright'
      end
      stack.push(env)
      self.latex << "\n\\begin{#{env}}\n"
    when 'strong'
      self.needs_hfill = false
      self.latex << '{\bfseries '
    when 'em'
      self.needs_hfill = false
      self.latex << '{\itshape '
    when 'br'
      # trick from http://www.tex.ac.uk/cgi-bin/texfaq2html?label=noline, since \\s in a row are invalid
      self.latex << (needs_hfill ? "\\hspace*{\\fill}\\\\\n" : "\\\\\n")
      self.needs_hfill = true
    end
  end
  
  def text(text)
    self.latex << FacturagemUtils.escape_latex(text)
  end
  
  def tag_end(name)
    case name
    when 'div'
      self.needs_hfill = false
      env = stack.pop
      self.latex << "\n\\end{#{env}}\n"
      self.needs_hfill = true
    when 'strong', 'em'
      self.needs_hfill = false
      self.latex << '}'
    end
  end
end