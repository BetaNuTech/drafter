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

require 'rails_helper'

RSpec.describe ChangeOrder, type: :model do
  include_context 'projects'
  include_context 'sample_projects'

  describe 'initialization' do
    it 'creates a change_order' do
      sample_project
      draw_cost = sample_draw_cost
      project_cost = draw_cost.project_cost
      expect {
        record = build(:change_order, project_cost:, draw_cost: )
        record.save
      }.to change{ChangeOrder.count}.by(1)
    end
  end

end
