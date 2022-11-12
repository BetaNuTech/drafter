require 'rails_helper'

RSpec.describe ChangeOrderService do
  include_context 'sample_projects'

  let(:project) { sample_project }
  let(:draw_cost) {
    cost = sample_draw_cost
    cost.project_cost = sample_project.project_costs.first
    cost.save!
    Invoice.create!(draw_cost: cost, user: user, amount: 50.0)
    cost.invoices.reload
    cost.total = cost.invoice_total
    cost.save
    cost
  }
  let(:project_cost) { draw_cost.project_cost }
  let(:funding_source) { sample_project.project_costs.last }
  let(:user) { sample_project.developers.first }
  let(:unauthorized_user) { sample_project.investors.first }

  describe 'initialization' do
    it 'initializes the service' do
      service = ChangeOrderService.new(user:, draw_cost:)
      expect(service.user).to eq(user)
      expect(service.draw_cost).to eq(draw_cost)
      expect(service.project).to eq(draw_cost.project)
      expect(service.change_order).to be_a(ChangeOrder)
    end
  end

  describe 'creating a ChangeOrder' do
    let(:valid_attributes) {
      {
        description: 'New change order',
        funding_source_id: funding_source.id
      }
    }

    describe 'when the draw cost total is less than the remaining draw cost budget' do
      it 'should not create a change order' do
        service = ChangeOrderService.new(user:, draw_cost:)
        expect {
          change_order = service.create(valid_attributes)
        }.to_not change{ChangeOrder.count}
        assert(service.errors?)
      end
    end

    describe 'when the invoice total is greater than the draw cost budget' do
      before do
        # add an invoice to the draw cost to bring it over budget
        Invoice.create!(draw_cost:, user: , amount: draw_cost.total)
        draw_cost.invoices.reload
        draw_cost.total = draw_cost.invoice_total
        draw_cost.save!
      end
      describe 'when there is sufficient project cost budget remaining' do
        it 'should create a change order for the invoice overage' do
          project_cost.total = 1.0
          project_cost.save!
          draw_cost.project_cost.reload

          assert(draw_cost.requires_change_order?)
          expect(project_cost.budget_balance).to be < 0.0

          service = ChangeOrderService.new(user:, draw_cost:)
          change_order = service.create(valid_attributes)

          refute(service.errors?)
          expect(change_order).to eq(service.change_order)
          expect(change_order.amount).to eq(99.0)
          expect(draw_cost.project_cost_overage).to eq(0.0)
          refute(draw_cost.over_budget?)
        end
      end
      describe 'when there is insufficient project cost budget remaining' do
        it 'should not create a change order' do
          funding_source.total = 1.0
          funding_source.save!

          service = ChangeOrderService.new(user:, draw_cost:)
          assert(service.funds_available?(funding_source))
          expect {
            change_order = service.create(valid_attributes)
          }.to_not change{ChangeOrder.count}
          assert(service.errors?)
        end
      end
    end

    describe 'removing an existing Change Order' do

    end

    describe 'approval and removing approval'

  end
  

end
