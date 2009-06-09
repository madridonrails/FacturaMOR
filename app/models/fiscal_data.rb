# == Schema Information
# Schema version: 7
#
# Table name: fiscal_datas
#
#  id               :integer(11)   not null, primary key
#  account_id       :integer(11)   not null
#  name             :string(255)   not null
#  name_for_sorting :string(255)   
#  cif              :string(255)   not null
#  iva_percent      :decimal(10, 2 
#  invoice_footer   :text          
#  irpf_percent     :decimal(10, 2 
#  charges_irpf     :boolean(1)    
#  logo_id          :integer(11)   
#

class FiscalData < ActiveRecord::Base
  attr_protected :account_id, :logo_id
  
  belongs_to :account
  belongs_to :country

  has_one :address, :as => :addressable, :dependent => :destroy
  belongs_to :logo
  validates_associated :logo
  validates_associated :account
  validates_associated :address
  
  # validates_presence_of tests for blank? and thus false does not pass
  validates_presence_of :name
  validates_presence_of :cif

# This method has been commented out because CIFs are gone, now we have only
# NIFs and with new codes that do not pass the old validation algorithm.
# 
#  def validate
#    return if cif.blank?
#    unless FacturagemUtils.fiscal_identifier?(cif)
#      errors.add(:cif, "el NIF/CIF es inválido")
#    end
#  end

  add_for_sorting_to :name
end
