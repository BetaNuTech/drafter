# == Schema Information
#
# Table name: change_orders
#
#  id                         :uuid             not null, primary key
#  amount                     :decimal(, )
#  description                :text
#  integration_attempt_at     :datetime
#  integration_attempt_number :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  draw_cost_id               :uuid             not null
#  external_task_id           :string
#  funding_source_id          :uuid             not null
#  project_cost_id            :uuid             not null
#
# Indexes
#
#  index_change_orders_on_draw_cost_id       (draw_cost_id)
#  index_change_orders_on_funding_source_id  (funding_source_id)
#  index_change_orders_on_project_cost_id    (project_cost_id)
#
# Foreign Keys
#
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
  has_one :project, through: :draw_cost
  has_one :draw, through: :draw_cost

  ### Validations
  validates :amount, presence: true, numericality: { greater_than: 0.0 }
  validates :draw_cost, uniqueness: { scope: :project_cost_id }
  validates :funding_source_id, exclusion: { in: ->(change_order) { [change_order.project_cost_id]}}
end
