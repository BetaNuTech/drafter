# == Schema Information
#
# Table name: project_costs
#
#  id                     :uuid             not null, primary key
#  approval_lead_time     :integer          default(0), not null
#  change_request_allowed :boolean          default(TRUE)
#  change_requestable     :boolean          default(TRUE)
#  cost_type              :integer          not null
#  drawable               :boolean          default(TRUE)
#  name                   :string           not null
#  state                  :string           default("pending"), not null
#  total                  :decimal(, )      default(0.0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  project_id             :uuid             not null
#
# Indexes
#
#  index_project_costs_on_project_id  (project_id)
#  project_costs_drawable_idx         (drawable,change_requestable,change_request_allowed)
#  project_costs_project_idx          (project_id,state)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
require 'rails_helper'

RSpec.describe ProjectCost, type: :model do
  include_context 'sample_draws'

  let(:init_draws) {
    draw
    draw_cost
    draw_cost.project_cost.update(total: 1000000.0)
    draw_cost.reload
    draw_cost_invoices
    draw_cost2
    draw_cost2.project_cost.update(total: 1000000.0)
    draw_cost2.reload
    draw_cost2_invoices
    draw2
    draw2_draw_cost
    draw2_draw_cost_invoices
    draw2_draw_cost2
    draw2_draw_cost2_invoices
    [draw, draw2]
  }

  let(:change_order1) {
    changeorder = build(:change_order,
                        draw_cost: draw_cost,
                        project_cost_id: draw_cost.project_cost_id,
                        funding_source_id: draw_cost2.project_cost_id,
                        amount: 1000.0)
                        changeorder.save!
                        changeorder
  }
  let(:change_order2) {
    changeorder = build(:change_order,
                        draw_cost: draw2_draw_cost,
                        project_cost_id: draw_cost.project_cost_id,
                        funding_source_id: draw_cost2.project_cost_id,
                        amount: 1000.0)
                        changeorder.save!
                        changeorder
  }

  let(:project_cost) { draw_cost.project_cost }
  let(:project_cost2) { draw_cost2.project_cost }

  describe 'initialization' do
    it 'creates a ProjectCost' do
      project_cost = build(:project_cost)
      assert(project_cost.save)
    end
  end

  describe 'totals' do

    before(:each) do
      init_draws
    end

    it 'returns total value of change orders' do
      expect(project_cost.change_order_total).to eq(0.0)
      change_order1; change_order2
      project_cost.change_orders.reload
      expect(project_cost.change_order_total).to eq(2000.0)
    end

    it 'returns the value of change orders with it as the funding source' do
      expect(project_cost2.change_order_funding_total).to eq(0.0)
      change_order1; change_order2
      expect(project_cost2.change_order_funding_total).to eq(2000.0)
    end

    it 'returns the total value of associated invoices' do
      expect(project_cost.invoice_total).to eq(8000.0)
      hide_invoice = project_cost.invoices.visible.last
      hide_invoice.state = 'removed'
      hide_invoice.save!
      project_cost.invoices.reload
      expect(project_cost.invoice_total).to eq(6000.0)
    end

    it 'returns the total of all draw costs' do
      expect(project_cost.draw_cost_total).to eq(8000.0)
      hide_cost = project_cost.draw_costs.visible.first
      hide_cost.state = 'withdrawn'
      hide_cost.save!
      project_cost.draw_costs.reload
      expect(project_cost.draw_cost_total).to eq(4000.0)
    end

    it 'returns the effective budget balance' do
      initial_balance = project_cost2.budget_balance
      change_order1; change_order2
      expected_new_balance = initial_balance - change_order1.amount - change_order2.amount
      project_cost2.reload
      expect(project_cost2.budget_balance).to eq(expected_new_balance)
    end

  end

  describe 'validating' do
    describe 'with TotalValidator' do
      before do
        init_draws
      end

      it 'prevents changing the amount to a value that would bring the budget_balance below zero' do
        assert(project_cost.update(total: 1000001.0))
        assert(project_cost.update(total: project_cost.draw_expensed_total - project_cost.change_order_total))
        refute(project_cost.update(total: 1.0))
      end
    end
  end



end
