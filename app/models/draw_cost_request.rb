# == Schema Information
#
# Table name: draw_cost_requests
#
#  id                 :uuid             not null, primary key
#  alert              :integer          default("ok"), not null
#  amount             :decimal(, )      default(0.0), not null
#  approval_due_date  :date
#  approved_at        :datetime
#  audit              :boolean          default(FALSE), not null
#  description        :text
#  plan_change        :boolean          default(FALSE), not null
#  plan_change_reason :text
#  state              :string           default("pending"), not null
#  total              :decimal(, )      default(0.0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  approver_id        :uuid
#  draw_cost_id       :uuid             not null
#  draw_id            :uuid             not null
#  organization_id    :uuid             not null
#  user_id            :uuid             not null
#
# Indexes
#
#  index_draw_cost_requests_on_draw_cost_id     (draw_cost_id)
#  index_draw_cost_requests_on_draw_id          (draw_id)
#  index_draw_cost_requests_on_organization_id  (organization_id)
#  index_draw_cost_requests_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (draw_cost_id => draw_costs.id)
#  fk_rails_...  (draw_id => draws.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (user_id => users.id)
#

class DrawCostRequest < ApplicationRecord
  include DrawCostRequests::StateMachine

  ALLOWED_PARAMS = [:amount, :description, :plan_change, :plan_change_reason, :draw_cost_id, :draw_id]

  ### Associations
  belongs_to :draw
  belongs_to :draw_cost
  belongs_to :user
  belongs_to :organization
  belongs_to :approver, class_name: 'User'
  has_one :project, through: :draw
  # has_many :cost_submissions

  ### Enums
  enum :alert, [:ok, :auditfail, :unclean]

end