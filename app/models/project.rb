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
  has_many :project_costs
  #has_many :invoices, through: :draws

  ### Validations
  validates :name, presence: true

  def draws_visible_to(user)
    case user
    when user.admin?
      draws
    when user.project_internal?(self)
      draws
    when user.project_consultant?(self)
      draws.visible
    else
      draws.where(organization: user.organization).visible
    end
  end
end
