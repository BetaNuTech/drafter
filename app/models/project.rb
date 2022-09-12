# == Schema Information
#
# Table name: projects
#
#  id          :uuid             not null, primary key
#  active      :boolean          default(TRUE), not null
#  budget      :decimal(, )      default(0.0), not null
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Project < ApplicationRecord
  ### Concerns
  include Projects::Users

  ### Params
  ALLOWED_PARAMS = [:id, :name, :description, :budget].freeze

  ### Associations
  has_many :system_events, as: :event_source, dependent: :destroy
  has_many :draws, dependent: :destroy
  has_many :draw_costs, through: :draws
  has_many :draw_cost_requests, through: :draws

  ### Validations
  validates :name, presence: true
end
