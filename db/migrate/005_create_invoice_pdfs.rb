class CreateInvoicePdfs < ActiveRecord::Migration
  def self.up
    create_table :invoice_pdfs do |t|
      t.column :invoice_id, :integer, :null => false
      t.column :data, :binary, :null => false
    end
  end

  def self.down
    drop_table :invoice_pdfs
  end
end
