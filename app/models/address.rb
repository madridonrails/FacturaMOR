# == Schema Information
# Schema version: 7
#
# Table name: addresses
#
#  id               :integer(11)   not null, primary key
#  street1          :string(255)   
#  street2          :string(255)   
#  city             :string(255)   
#  province         :string(255)   
#  postal_code      :string(255)   
#  country_id       :integer(11)   
#  addressable_id   :integer(11)   
#  addressable_type :string(255)   
#

class Address < ActiveRecord::Base
  belongs_to :country
  belongs_to :addressable, :polymorphic => true
  
  validates_presence_of :country
end
