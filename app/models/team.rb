# == Schema Information
#
# Table name: teams
#
#  id          :uuid             not null, primary key
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Team < ApplicationRecord
  ### Constants
  include Teams::TeamUsers
  ALLOWED_PARAMS = [:name, :description]

  ### Associations
  has_many :properties

  ### Validations
  validates :name, presence: true, uniqueness: true
end
