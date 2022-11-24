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
  has_many :draw_costs, through: :draws
  has_many :project_costs, dependent: :destroy

  ### Validations
  validates :name, presence: true

  def all_system_events
    SystemEvent.where(event_source: self).or(SystemEvent.where(incidental: self))
  end

  def draws_visible_to(user)
    case user
    when user.admin?
      draws
    when user.project_internal?(self)
      draws
    when user.project_investor?(self)
      draws.visible
    else
      draws.visible
    end
  end

  def allow_new_draw?
    !issues? &&
      draws.pending.none? &&
      draws.rejected.none?
  end

  def budget_total
    project_costs.sum(:total)
  end

  def draw_total
    draws.map(&:draw_cost_total).sum
  end

  def total_contract_remaining
    budget_total - draw_total
  end

  def sorted_members
    members = project_users.includes(:project_role, :user).to_a
    out = []
    ProjectRole::HIERARCHY.each do |role|
      out << members.select{|member| member.project_role.slug == role.to_s }.
        sort_by{|member| member.user.name }
    end
    out.flatten
  end

  def issues?(user=nil)
    issues(user).any?
  end

  def issues(user=nil)
    items = []

    pc_issues = project_cost_issues
    items << pc_issues if pc_issues.any?

    u_issues = user_issues(user)
    items << u_issues if u_issues.any?

    items
  end

  def user_issues(user=nil)
    items = []
    items += ['Not a member of this Project', [ user ]] unless role_for(user).present?

    items
  end

  def project_cost_issues
    items = []
    missing_totals = project_costs.select{ |cost| cost.missing_total? }
    if missing_totals.any?
      items = ['One or more Project Costs do not have a budget', missing_totals]
    end

    items
  end

  def allow_project_cost_changes?
    draws.where(state: Draw::APPROVED_STATES).none?
  end

end
