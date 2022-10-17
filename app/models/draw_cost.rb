# == Schema Information
#
# Table name: draw_costs
#
#  id                           :uuid             not null, primary key
#  approved_at                  :datetime
#  contingency                  :decimal(, )      default(0.0), not null
#  plan_change                  :boolean          default(FALSE), not null
#  plan_change_approved_at      :datetime
#  plan_change_approved_by_desc :text
#  plan_change_desc             :text
#  state                        :string           default("pending"), not null
#  total                        :decimal(, )      default(0.0), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  approver_id                  :uuid
#  draw_id                      :uuid             not null
#  plan_change_approver_id      :uuid
#  project_cost_id              :uuid             not null
#
# Indexes
#
#  draw_costs_assoc_idx                         (draw_id,project_cost_id,approver_id)
#  draw_costs_draw_state_idx                    (draw_id,state)
#  index_draw_costs_on_approver_id              (approver_id)
#  index_draw_costs_on_draw_id                  (draw_id)
#  index_draw_costs_on_plan_change_approver_id  (plan_change_approver_id)
#  index_draw_costs_on_project_cost_id          (project_cost_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_id => draws.id)
#  fk_rails_...  (plan_change_approver_id => users.id)
#  fk_rails_...  (project_cost_id => project_costs.id)
#
class DrawCost < ApplicationRecord
  ### Concerns
  include DrawCosts::StateMachine

  ALLOWED_PARAMS = %i{project_cost_id total contingency plan_change plan_change_desc}.freeze
  
  ### Associations
  belongs_to :draw
  belongs_to :project_cost
  belongs_to :approver, class_name: 'User', optional: true
  belongs_to :plan_change_approver, class_name: 'User', optional: true
  has_one :project, through: :draw
  has_one :organization, through: :draw
  has_many :invoices, dependent: :destroy

  ### Validations
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0.0}
  validates :project_cost_id, presence: true, uniqueness: {scope: [:draw_id]}, allow_blank: false
  validates :state, presence: true

end
