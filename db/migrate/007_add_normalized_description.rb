class AddNormalizedDescription < ActiveRecord::Migration
  def self.up
    add_column :invoice_lines, :description_for_sorting, :string, :limit => 1024
    InvoiceLine.reset_column_information
    InvoiceLine.find(:all).each {|il| il.description = il.description; il.save(false)}
  end

  def self.down
    remove_column :invoice_lines, :description_for_sorting
  end
end
