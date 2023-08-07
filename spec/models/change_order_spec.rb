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
  let(:draw_cost) { sample_draw_cost }
  let(:project_cost) { sample_draw_cost.project_cost }
  let(:funding_source) { sample_project_non_contingency_project_costs.first }
  let(:service) {ChangeOrderService.new(user: developer_user, draw_cost: draw_cost)}
  let(:change_order_attrs) {
    { amount: draw_cost.total, description: 'Test Change Order 1', funding_source_id: funding_source.id }
  }
  let(:change_order) {
    co = service.create(change_order_attrs)
    raise 'Failed to create change_order test variable' if service.errors?

    co
  }

  describe 'validations' do
    let(:draw_cost) { sample_draw_cost }
    let(:funding_source) { sample_project_non_contingency_project_costs.first }
    describe 'amount' do
      let(:service) {ChangeOrderService.new(user: developer_user, draw_cost: draw_cost)}
      it 'should not allow an amount exceeding the funding source balance' do
        draw_cost_invoices
        draw_cost.reload
        draw_cost.update_column(:total, draw_cost.invoice_total)
        funding_source.update(total: 1.0)
        service.create(change_order_attrs)
        assert(service.errors?)
        funding_source.update(total: 5000.0)
        service.create(change_order_attrs)
        refute(service.errors?)
      end
    end
  end

  describe 'state machine' do
    before do
      draw_documents
      draw_cost_invoices
      draw_cost.reload
      draw_cost.update(total: draw_cost.invoice_total)
      project_cost.update(total: draw_cost.total * 2.0)
      project_cost.reload
      funding_source.update(total: draw_cost.total * 2.0)
      funding_source.reload
      draw_cost.reload
      draw.reload
    end

    describe 'approval event' do
      before do
        change_order
        assert(draw.trigger_event(event_name: :submit))
        change_order.reload
      end
      it 'approves the Change Order' do
        assert(change_order.trigger_event(event_name: :approve))
      end
      it 'allows approving a Change Order if the Draw Cost is in the rejected state' do
        draw_cost.update_column(:state, :rejected)
        change_order.reload
        assert(change_order.trigger_event(event_name: :approve))
      end
      it 'approves the change order if the change order task is approved' do
        task = change_order.project_tasks.first
        ProjectTaskService.new(task).approve
        change_order.reload
        assert(change_order.approved?)
      end
    end
  end # 'approval event'

  describe 'withdrawl' do
    before do
      draw_cost_invoices
      draw_cost.reload
      draw_cost.update(total: draw_cost.invoice_total)
    end
    it 'allows change orders to be withdrawn if the draw cost is pending or rejected' do
      assert(draw_cost.pending?)
      assert(change_order.trigger_event(event_name: :withdraw))
      change_order.reload
      assert(change_order.withdrawn?)
    end
    it 'prevents change orders to be withdrawn if the draw cost is in a non-modifiable state' do
      assert(draw_cost.pending?)
      assert(draw_cost.trigger_event(event_name: :submit))
      draw_cost.reload
      assert(change_order.draw_cost.project_cost.change_request_allowed?)
      refute(change_order.trigger_event(event_name: :withdraw))
      change_order.reload
      refute(change_order.withdrawn?)
    end
  end # describe 'withdrawl'

end
