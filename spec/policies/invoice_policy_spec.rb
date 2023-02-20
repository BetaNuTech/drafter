require 'rails_helper'

RSpec.describe InvoicePolicy do
  include_context 'sample_draws'

  let(:invoice1) { draw_cost_invoices.first }

  describe 'approve?' do
    before do
      invoice1.update(state: :processed)
      draw_cost.update(state: :submitted)
      draw.update(state: :submitted)
    end

    describe 'when an invoice is clean' do
      it 'should allow finance users to approve an invoice' do
        user = sample_project.finance.first
        refute(draw_cost.consult?)
        refute(invoice1.consult?)
        policy = InvoicePolicy.new(user, invoice1)
        assert(policy.approve?)
      end
    end
    describe 'when an invoice is not clean' do
      let(:change_order_amount) { 1000.0 }
      let(:contingency_project_cost) {
        cost = create(:project_cost, project: sample_project, name: 'Sample Contingency')
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

      before do
        change_order
      end

      it 'does not allow finance to approve the invoice' do
        user = sample_project.finance.first
        policy = InvoicePolicy.new(user, invoice1)
        refute(policy.approve?)
      end
      it 'allows managers to approve the invoice' do
        change_order
        user = sample_project.managers.first
        policy = InvoicePolicy.new(user, invoice1)
        assert(policy.approve?)
      end
      it 'allows managers to approve the invoice' do
        change_order
        user = sample_project.owners.first
        policy = InvoicePolicy.new(user, invoice1)
        assert(policy.approve?)
      end
    end
  end
end
