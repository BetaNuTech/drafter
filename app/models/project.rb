# == Schema Information
#
# Table name: projects
#
#  id          :uuid             not null, primary key
#  active      :boolean          default(TRUE), not null
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Project < ApplicationRecord
  ### Concerns
  include Projects::Users

  ### Params
  ALLOWED_PARAMS = [:name, :description, :budget].freeze

  ### Associations
  has_many :system_events, as: :event_source, dependent: :destroy
  has_many :draws, dependent: :destroy
  has_many :project_costs, dependent: :destroy

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

  def allow_new_draw?(organization)
    draws.pending.for_organization(organization).none?
  end

  def budget_total
    project_costs.sum(:total)
  end
end
