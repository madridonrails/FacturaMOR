# == Schema Information
# Schema version: 7
#
# Table name: countries
#
#  id               :integer(11)   not null, primary key
#  name             :string(255)   
#  name_for_sorting :string(255)   
#

class Country < ActiveRecord::Base
  add_for_sorting_to :name
end
