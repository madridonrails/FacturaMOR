# == Schema Information
# Schema version: 7
#
# Table name: invoices
#
#  id                    :integer(11)   not null, primary key
#  url_id                :string(255)   not null
#  account_id            :integer(11)   not null
#  customer_id           :integer(11)   not null
#  number                :string(255)   not null
#  date                  :date          
#  year                  :integer(11)   
#  account_name          :string(255)   not null
#  account_cif           :string(255)   not null
#  account_street1       :string(255)   
#  account_street2       :string(255)   
#  account_city          :string(255)   
#  account_province      :string(255)   
#  account_postal_code   :string(255)   
#  account_country_id    :integer(11)   
#  account_country_name  :string(255)   
#  customer_name         :string(255)   not null
#  customer_cif          :string(255)   not null
#  customer_street1      :string(255)   
#  customer_street2      :string(255)   
#  customer_city         :string(255)   
#  customer_province     :string(255)   
#  customer_postal_code  :string(255)   
#  customer_country_id   :integer(11)   
#  customer_country_name :string(255)   
#  irpf_percent          :decimal(10, 2 
#  irpf                  :decimal(10, 2 
#  iva_percent           :decimal(10, 2 
#  iva                   :decimal(10, 2 
#  discount_percent      :decimal(10, 2 
#  discount              :decimal(10, 2 
#  total                 :decimal(10, 2 
#  paid                  :boolean(1)    not null
#  notes                 :text          
#  footer                :text          
#  logo_id               :integer(11)   
#  created_at            :datetime      
#  updated_at            :datetime      
#  tax_base              :decimal(10, 2 
#

require 'set'

class Invoice < ActiveRecord::Base
  # We convert "F10-2007" into ["F", 10, "-", 2007] to get a mix of lexicographic/numeric
  # ordering per components delegating to Array#<=>.
  attr_accessor :number_for_sorting

  # these fields are always computed server-side
  attr_protected :discount, :iva, :tax_base, :total
  attr_protected :logo

  belongs_to :account
  belongs_to :customer
  has_many :lines, :class_name => 'InvoiceLine', :dependent => :destroy

  belongs_to :logo

  has_one :pdf, :class_name => 'InvoicePdf', :dependent => :destroy

  # We need to run this setter before validation so that year is set
  # when we check uniqueness of number. Otherwise the validator is not
  # effective because year IS NOT NULL ends up (rightly) in the query.
  before_validation :set_year

  before_save :ensure_percents_are_not_nil
  before_save :compute_totals

  validates_presence_of   :number
  validates_uniqueness_of :number, :scope => [:account_id, :year], :message => "existe ya una factura con este número"
  validates_presence_of   :date, :message => "fecha inválida"
  validates_presence_of   :account
  validates_presence_of   :customer

  # This regexp is used to partition invoice numbers in maximal numeric and non-numeric
  # components, that way "F07_0089" is scanned as ("F", "07", "_", "0089").
  REGEXP_FOR_NUMBER_PARTITIONING = %r{\D+|\d+}

  def set_year
    self.year = date.year
  end

  def before_create
    compute_and_set_url_id
  end

  def before_update
    self_in_db = Invoice.find(id, :select => 'id, number')
    compute_and_set_url_id if number != self_in_db.number
  end

  def after_find
    self.number_for_sorting = number.scan(REGEXP_FOR_NUMBER_PARTITIONING).map {|c| c =~ /\d/ ? c.to_i : c}
  end

  def to_param
    url_id
  end

  def self.sort_by_number_asc(invoices)
    is = Set.new(invoices)
    is_per_year = is.classify(&:year).sort_by {|k, v| k}.map {|y| y[1]}
    is_per_year.map {|y| y.sort_by {|i| i.number_for_sorting}}.flatten
  rescue
    invoices.sort_by {|i| i.date}
  end

  def <=>(another_invoice)
    i = (another_invoice.date <=> date rescue 0)
    if i == 0
      begin
        i = another_invoice.number_for_sorting <=> number_for_sorting
        i = another_invoice.number <=> number if i.nil?
      rescue Exception => e
        # If the user is in the middle of changing his invoice number pattern, as Agustin
        # did while using the application, perhaps the number_for_sorting are not comparable.
        # For instance "07_0003" with "Serv_07_0004", where the first components are a number
        # and a string respectively. That's why we put a rescue block with lexicographic
        # ordering as fallback.
        i = another_invoice.number <=> number
      end
    end
    return i
  end

  def logo_needs_update?
    logo != account.logo
  end

  alias_method :original_account=, :account=
  def account=(account)
    self.account_name         = account.fiscal_data.name
    self.account_cif          = account.fiscal_data.cif
    self.account_street1      = account.fiscal_data.address.street1
    self.account_street2      = account.fiscal_data.address.street2
    self.account_city         = account.fiscal_data.address.city
    self.account_province     = account.fiscal_data.address.province
    self.account_postal_code  = account.fiscal_data.address.postal_code
    self.account_country_id   = account.fiscal_data.address.country.id
    self.account_country_name = account.fiscal_data.address.country.name
    self.original_account     = account
  end

  def account_needs_update?
    account_name        != account.fiscal_data.name                ||
    account_cif         != account.fiscal_data.cif                 ||
    account_street1     != account.fiscal_data.address.street1     ||
    account_street2     != account.fiscal_data.address.street2     ||
    account_city        != account.fiscal_data.address.city        ||
    account_province    != account.fiscal_data.address.province    ||
    account_postal_code != account.fiscal_data.address.postal_code ||
    account_country_id  != account.fiscal_data.address.country.id
  end

  alias_method :original_customer=, :customer=
  def customer=(customer)
    self.customer_name         = customer.name
    self.customer_cif          = customer.cif
    self.customer_street1      = customer.address.street1
    self.customer_street2      = customer.address.street2
    self.customer_city         = customer.address.city
    self.customer_province     = customer.address.province
    self.customer_postal_code  = customer.address.postal_code
    self.customer_country_id   = customer.address.country.id
    self.customer_country_name = customer.address.country.name
    self.original_customer     = customer
  end

  def customer_needs_update?
    customer_name        != customer.name                ||
    customer_cif         != customer.cif                 ||
    customer_street1     != customer.address.street1     ||
    customer_street2     != customer.address.street2     ||
    customer_city        != customer.address.city        ||
    customer_province    != customer.address.province    ||
    customer_postal_code != customer.address.postal_code ||
    customer_country_id  != customer.address.country.id
  end

  # nils are not coerced to BigDecimal, we do it by hand to
  # ensure compute_totals has everything defined
  def ensure_percents_are_not_nil
    self.discount_percent = 0 if discount_percent.nil?
    self.iva_percent      = 0 if iva_percent.nil?
    self.irpf_percent     = 0 if irpf_percent.nil?
  end

  # In addition to a simple enumeration we support most patterns of the form
  # year + separator + code (or its reverse), including
  #
  #   0003/2007, used by ana
  #   07_0003,   used by pei
  #   F4-2007,   used by cabreramc
  #   2007/3,    used by fxn
  #
  # The basic heuristic is to try to identify the year first, and then
  # apply our custom String#isucc to the other part, see environment.rb.
  # It would be too confusing to explain the details here, please follow
  # the code.
  #
  # This is tested in test/unit/number_guesser_test.rb, please maintain
  # that test suite if unknown patterns arise and we add support for them.
  def self.guess_next_number(account)
    invoices = account.last_invoices(2)
    invoices.pop if invoices.size == 2 && invoices.first.year != invoices.last.year
    logger.debug("guessing next invoice from #{invoices.map(&:number).join(" and ")}.")
    guess_next_number_aux(invoices.map(&:number))
  end

  class << self
    # Expects an array of invoice numbers, always as strings, most recent first.
    def guess_next_number_aux(numbers)
      current_year = Date.today.year.to_s

      # This is our default if the account has no invoices.
      return "#{current_year}_0001" if numbers.empty?

      # Convenience array for include? testing below.
      years = []
      0.upto(3) {|i| years << current_year[i..3]}

      # Break the number in parts and select the numeric ones as strings.
      parts = numbers.first.scan(REGEXP_FOR_NUMBER_PARTITIONING)
      ints = []
      parts.each_with_index {|p, i| ints << [p, i] if p =~ /^\d+$/}

      case ints.length
      when 0
        # Unlikely, this means there's no digit and there are separators, as in FG-HT.
        return numbers.first.isucc
      when 1
        # Increment that number as string.
        parts[ints[0][1]].isucc!
        return parts.join('')
      when 2
        if years.include?(ints[0][0]) && !years.include?(ints[1][0])
          parts[ints[1][1]].isucc!
          return parts.join('')
        elsif !years.include?(ints[0][0]) && years.include?(ints[1][0])
          parts[ints[0][1]].isucc!
          return parts.join('')
        elsif !years.include?(ints[0][0]) && !years.include?(ints[1][0])
          parts[ints[1][1]].isucc! # TODO: can we do better?
          return parts.join('')
        else
          parts2 = numbers.last.scan(REGEXP_FOR_NUMBER_PARTITIONING)
          ints2 = []
          parts2.each_with_index {|p, i| ints2 << [p, i] if p =~ /^\d+$/}
          if 2 == ints.length
            if ints[0][0] == ints2[0][0] # year in first integer
              parts[ints[1][1]].isucc!
              return parts.join('')
            elsif ints[1][0] == ints2[1][0] # year in second integer
              parts[ints[0][1]].isucc!
              return parts.join('')
            end
          end
        end
      end
      return nil
    end
    private :guess_next_number_aux
  end

  def compute_totals
    if self.lines.size > 0
      taxable = 0.0.to_d
      self.lines.each do |line|
        taxable += line.total
      end
      self.discount = (taxable*discount_percent/100.0.to_d rescue 0.0.to_d).round(2)
      self.tax_base = taxable - discount
      self.iva      = (tax_base*iva_percent/100.0.to_d rescue 0.0.to_d).round(2)
      self.irpf     = (tax_base*irpf_percent/100.0.to_d rescue 0.0.to_d).round(2)
      self.total    = tax_base - irpf + iva
    else
      self.discount = 0.0.to_d
      self.tax_base = 0.0.to_d
      self.irpf     = 0.0.to_d
      self.iva      = 0.0.to_d
      self.total    = 0.0.to_d
    end
  end

  def compute_and_set_url_id
    candidate = FacturagemUtils.normalize_for_url_id(number)
    invoice = Invoice.find_by_account_id_and_url_id(account_id, candidate)
    return if self == invoice # unlikely
    # invoice numbers are guaranteed to be unique within a year, but
    # not across years, if there's a clash we add the year
    candidate += "-#{date.year}" if invoice
    self.url_id = candidate
  end
  private :compute_and_set_url_id

  def has_logo?
    logo
  end
end
