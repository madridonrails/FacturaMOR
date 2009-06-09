# == Schema Information
# Schema version: 7
#
# Table name: invoice_pdfs
#
#  id         :integer(11)   not null, primary key
#  invoice_id :integer(11)   not null
#  data       :binary        not null
#

# Generated PDFs are stored in the database. This is the model
# that represents them.
#
# This is NOT done to avoid regeneration. It is done so that we are always ready
# to return an invoice as it was generated. Thus, if we change the template for
# we can still return original PDFs, as long as they were created.
class InvoicePdf < ActiveRecord::Base
  belongs_to :invoice
end
