# == Schema Information
#
# Table name: change_orders
#
#  id                         :uuid             not null, primary key
#  amount                     :decimal(, )
#  approved_at                :datetime
#  approved_by_desc           :string
#  description                :text
#  integration_attempt_at     :datetime
#  integration_attempt_number :integer
#  state                      :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  approved_by_id             :uuid
#  draw_cost_id               :uuid             not null
#  external_task_id           :string
#  funding_source_id          :uuid             not null
#  project_cost_id            :uuid             not null
#
# Indexes
#
#  index_change_orders_on_approved_by_id     (approved_by_id)
#  index_change_orders_on_draw_cost_id       (draw_cost_id)
#  index_change_orders_on_funding_source_id  (funding_source_id)
#  index_change_orders_on_project_cost_id    (project_cost_id)
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_id => users.id)
#  fk_rails_...  (draw_cost_id => draw_costs.id)
#  fk_rails_...  (funding_source_id => project_costs.id)
#  fk_rails_...  (project_cost_id => project_costs.id)
#
class ChangeOrder < ApplicationRecord
  ALLOWED_PARAMS = %i{description funding_source_id}.freeze

  ### Associations
  belongs_to :project_cost
  belongs_to :draw_cost
  belongs_to :funding_source, class_name: 'ProjectCost'
  belongs_to :approved_by, class_name: 'User', optional: true
  has_one :project, through: :draw_cost
  has_one :draw, through: :draw_cost

  ### Validations
  validates :amount, presence: true, numericality: { greater_than: 0.0 }
  validates :draw_cost, uniqueness: { scope: :project_cost_id }
  validates :funding_source_id, exclusion: { in: ->(change_order) { [change_order.project_cost_id]}}

  def approve(user)
    self.approved_by = user
    self.approved_at = Time.current
    save
  end

  def unapprove
    self.approved_by = nil
    self.approved_at = nil
    save
  end
end
