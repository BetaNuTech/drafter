# == Schema Information
#
# Table name: draw_costs
#
#  id              :uuid             not null, primary key
#  approved_at     :datetime
#  state           :string           default("pending"), not null
#  total           :decimal(, )      default(0.0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  approver_id     :uuid
#  draw_id         :uuid             not null
#  project_cost_id :uuid             not null
#
# Indexes
#
#  draw_costs_assoc_idx                 (draw_id,project_cost_id,approver_id)
#  draw_costs_draw_state_idx            (draw_id,state)
#  index_draw_costs_on_draw_id          (draw_id)
#  index_draw_costs_on_project_cost_id  (project_cost_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_id => draws.id)
#  fk_rails_...  (project_cost_id => project_costs.id)
#
class DrawCost < ApplicationRecord
  ### Concerns
  include DrawCosts::StateMachine

  class ProjectCostValidator < ActiveModel::Validator
    def validate(record)
      if record.project.draw_costs.
          visible.
          where(project_cost_id: record.project_cost_id).
          where.not(id: record.id).
          any?
        record.errors.add(:project_cost_id, 'There is already a Draw Cost for this Project Cost')
      end
    end
  end

  ALLOWED_PARAMS = %i{project_cost_id total}.freeze

  ### Associations
  belongs_to :draw
  belongs_to :project_cost
  belongs_to :approver, class_name: 'User', optional: true
  belongs_to :plan_change_approver, class_name: 'User', optional: true
  has_one :project, through: :draw
  has_one :organization, through: :draw
  has_many :invoices, dependent: :destroy
  has_many :change_orders, dependent: :destroy

  ### Delegations
  delegate :name, to: :project_cost

  ### Validations
  validates_with ProjectCostValidator
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0.0}
  validates :state, presence: true


  def invoice_total
    invoices.totalable.sum(:amount)
  end

  def subtotal
    total - invoice_total
  end

  def invoice_mismatch?
    0.0 != subtotal
  end

  def project_cost_overage
    balance = project_cost.budget_balance
    balance.negative? ? ( balance * -1.0 ) : 0.0
  end

  def over_budget?
    subtotal.negative? || project_cost_overage.positive?
  end

  def change_order_total
    change_orders.sum(:amount)
  end

  def requires_change_order?
    allow_new_change_order?
  end

  def allow_new_change_order?
    project_cost.change_request_allowed? && project_cost_overage.positive? 
  end
end
