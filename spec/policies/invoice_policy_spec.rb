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

    it 'should allow finance users to approve an invoice' do
      user = sample_project.finance.first
      refute(draw_cost.consult?)
      policy = InvoicePolicy.new(user, invoice1)
      assert(policy.approve?)
    end

    it 'should allow manager users to approve an invoice' do
      user = sample_project.managers.first
      refute(draw_cost.consult?)
      policy = InvoicePolicy.new(user, invoice1)
      assert(policy.approve?)
    end

    it 'should not allow developer users to approve an invoice' do
      user = sample_project.developers.first
      refute(draw_cost.consult?)
      policy = InvoicePolicy.new(user, invoice1)
      refute(policy.approve?)
    end
  end
end
