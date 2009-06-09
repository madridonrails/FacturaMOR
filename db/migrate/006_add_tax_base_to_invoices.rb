class AddTaxBaseToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :tax_base, :decimal, :precision => 10, :scale => 2
    Invoice.reset_column_information
    Invoice.find(:all).each {|i| i.save(false)}
  end

  def self.down
    remove_column :invoices, :tax_base
  end
end
