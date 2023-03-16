# == Schema Information
#
# Table name: change_orders
#
#  id                         :uuid             not null, primary key
#  amount                     :decimal(, )
#  description                :text
#  integration_attempt_at     :datetime
#  integration_attempt_number :integer
#  state                      :string           default("pending")
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  draw_cost_id               :uuid             not null
#  external_task_id           :string
#  funding_source_id          :uuid             not null
#  project_cost_id            :uuid             not null
#
# Indexes
#
#  index_change_orders_on_draw_cost_id_and_state  (draw_cost_id,state)
#  index_change_orders_on_funding_source_id       (funding_source_id)
#  index_change_orders_on_project_cost_id         (project_cost_id)
#
# Foreign Keys
#
#  fk_rails_...  (draw_cost_id => draw_costs.id)
#  fk_rails_...  (funding_source_id => project_costs.id)
#  fk_rails_...  (project_cost_id => project_costs.id)
#

require 'rails_helper'

RSpec.describe ChangeOrder, type: :model do
  include_context 'projects'
  include_context 'sample_draws'

  describe 'initialization' do
    it 'creates a change_order' do
      sample_project
      draw_cost = sample_draw_cost
      project_cost = draw_cost.project_cost
      expect {
        record = build(:change_order, project_cost:, draw_cost:, amount: 1.0 )
        record.save
      }.to change{ChangeOrder.count}.by(1)
    end
  end

  let(:user) { developer_user }

  describe 'validations' do
    let(:draw_cost) { sample_draw_cost }
    let(:funding_source) { sample_project_non_contingency_project_costs.first }
    describe 'amount' do
      let(:service) {ChangeOrderService.new(user: developer_user, draw_cost: draw_cost)} 
      it 'should not allow an amount exceeding the funding source balance' do
        funding_source.update(total: 1.0)
        attrs = {amount: 1000.0, description: 'Test Change Order 1', funding_source_id: funding_source.id}
        service.create(attrs)
        assert(service.errors?)
        funding_source.update(total: 5000.0)
        service.create(attrs)
        refute(service.errors?)
      end
    end
  end

end
