# == Schema Information
# Schema version: 7
#
# Table name: chpass_tokens
#
#  id         :integer(11)   not null, primary key
#  token      :string(255)   not null
#  account_id :integer(11)   
#  created_at :datetime      
#

class ChpassToken < ActiveRecord::Base
  belongs_to :account
end
