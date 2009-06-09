# == Schema Information
# Schema version: 7
#
# Table name: invoice_lines
#
#  id                      :integer(11)   not null, primary key
#  invoice_id              :integer(11)   not null
#  amount                  :decimal(10, 2 
#  description             :string(1024)  
#  price                   :decimal(10, 2 
#  total                   :decimal(10, 2 
#  description_for_sorting :string(1024)  
#

# Invoice lines compute automatically their total.
#
# That does not trigger the recomputation of the invoice they belong to, though.
# Invoices are responsible of keeping their totals up to date.
class InvoiceLine < ActiveRecord::Base
  belongs_to  :invoice
  before_save :compute_total
  
  add_for_sorting_to :description
  
  def compute_total
    # nil is not converted to 0 as BigDecimal
    self.amount = 0.0.to_d if amount.nil?
    self.price = 0.0.to_d if price.nil?
    self.total = (amount * price).round(2)
  end
end
