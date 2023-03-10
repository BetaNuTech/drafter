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
require 'rails_helper'

RSpec.describe DrawCost, type: :model do
  include_context 'sample_draws'

  let(:user) { developer_user }
  let(:change_order_amount) { 1000.0 }
  let(:contingency_project_cost) {
    cost = create(:project_cost, project: sample_project, name: 'Sample Contingency', total: 1000000.0)
    sample_project.project_costs.reload
    cost
  }
  let(:change_order) {
    project_cost = draw_cost.project_cost
    contingency_project_cost
    create(:change_order,
           amount: change_order_amount,
           draw_cost: draw_cost,
           project_cost: draw_cost.project_cost,
           funding_source: contingency_project_cost)
  }

  describe 'initialization' do
    it 'creates a DrawCost' do
      draw_cost = build(:draw_cost, draw: draw, project_cost: sample_project.project_costs.first)
      assert(draw_cost.save)
    end
  end

  describe 'view helpers' do
    it 'returns the css class for the cost type' do
      draw_cost = build(:draw_cost, draw: sample_project.draws.first)
      expect(draw_cost.state_css_class).to eq('secondary')
    end
  end

  describe 'state machine' do
    describe 'submission' do
      it 'will not transition to submitted if there are no invoices' do
        assert(draw_cost.pending?)
        draw_cost.trigger_event(event_name: :submit, user: )
        draw_cost.save
        draw_cost.reload
        refute(draw_cost.submitted?)
      end
      it 'will not transition to submitted if there are any rejected invoices' do
        invoices
        invoice = draw_cost.invoices.last
        invoice.state = 'rejected'
        invoice.save!

        assert(draw_cost.pending?)
        draw_cost.trigger_event(event_name: :submit, user: )
        draw_cost.save
        draw_cost.reload
        refute(draw_cost.submitted?)
      end
      it 'automatically submits pending invoices' do
        draw_cost.state = 'pending'
        draw_cost.save!

        invoices
        draw_cost.reload
        draw_cost.trigger_event(event_name: :submit, user: )
        draw_cost.save
        draw_cost.reload
        assert(draw_cost.submitted?)
      end
      it 'automatically creates tasks for change orders' do
        draw_cost.state = 'pending'
        draw_cost.save!
        invoices
        change_order
        expect(change_order.project_tasks.count).to eq(0)
        draw_cost.reload
        draw_cost.trigger_event(event_name: :submit, user: )
        change_order.reload
        expect(change_order.project_tasks.count).to eq(1)
      end
    end
  end
  
end
