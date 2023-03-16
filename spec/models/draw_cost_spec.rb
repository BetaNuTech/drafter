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
        draw_cost.update(total: draw_cost.total - change_order.amount)
        draw_cost.reload
        assert(draw_cost.allow_submit?)
        draw_cost.trigger_event(event_name: :submit, user: )
        change_order.reload
        expect(change_order.project_tasks.count).to eq(1)
      end
    end
  end

  describe 'using change orders' do
    let(:change_order1_amount) { 1000.0 }
    let(:change_order2_amount) { 777.0 }
    let(:contingency_project_cost) {
      cost = create(:project_cost, project: sample_project, name: 'Sample Contingency', total: 1000000.0)
      sample_project.project_costs.reload
      cost
    }
    let(:project_cost2) {
      sample_project_non_contingency_project_costs.
        select{|pc| pc.change_request_allowed? && pc != draw_cost.project_cost}.
        sample
    }
    let(:change_order1) {
      project_cost = draw_cost.project_cost
      contingency_project_cost
      create(:change_order,
             amount: change_order_amount,
             draw_cost: draw_cost,
             project_cost: draw_cost.project_cost,
             funding_source: contingency_project_cost)
    }
    let(:change_order2) {
      project_cost = draw_cost.project_cost
      contingency_project_cost
      create(:change_order,
             amount: change_order2_amount,
             draw_cost: draw_cost,
             project_cost: draw_cost.project_cost,
             funding_source: project_cost2)
    }

    before do
      draw_cost_invoices
    end

    describe 'determining if the draw cost is over-funded by change orders' do
      it 'returns true if the total of visible change orders exceeds the draw cost subtotal' do
        # Having a zero balance and change orders there is no overfunding
        expect(draw_cost.subtotal).to eq(0.0)
        refute(draw_cost.overfunded_by_change_orders?)

        # With excess change orders
        change_order1; change_order2
        draw_cost.reload
        assert(draw_cost.overfunded_by_change_orders?)
      end
    end
    describe 'determining if the draw cost requires a change order to be fully funded' do
      it 'returns true if the value of invoices exceeds the draw cost "amount"' do
        refute(draw_cost.requires_change_order?)
        draw_cost.update(total: 3000)
        assert(draw_cost.requires_change_order?)
        change_order1
        draw_cost.reload
        assert(draw_cost.allow_new_change_order?)
        refute(draw_cost.requires_change_order?)
      end
    end
    describe 'submission validation' do
      it 'disallows submission if the draw cost is over funded by change orders' do
        assert(draw_cost.allow_submit?)
        change_order1
        refute(draw_cost.allow_submit?)
      end
      it 'disallows submission if the draw cost is not fully funded' do
        draw_cost.update(total: draw_cost.total - change_order1_amount)
        refute(draw_cost.allow_submit?)
        change_order1
        assert(draw_cost.allow_submit?)
      end
      it 'disallows submission if any change orders are rejected' do
        assert(draw_cost.allow_submit?)
        draw_cost.invoices.first.update(state: :rejected)
        draw_cost.reload
        #binding.pry
        refute(draw_cost.allow_submit?)
      end
    end
  end
  
end
