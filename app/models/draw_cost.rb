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
  
  ### Associations
  belongs_to :approver, class_name: 'User'
  belongs_to :draw
  belongs_to :plan_change_approver, class_name: 'User'
  belongs_to :project_cost

end
