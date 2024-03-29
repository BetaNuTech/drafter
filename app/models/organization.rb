# == Schema Information
#
# Table name: organizations
#
#  id          :uuid             not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Organization < ApplicationRecord
  ALLOWED_PARAMS = [:id, :name, :description].freeze

  has_many :users
  validates :name, presence: true
end
