require 'rails_helper'

RSpec.describe ChangeOrdersController, type: :controller do
  include_context 'sample_projects'
  render_views

  let(:project) { sample_project }
  let(:draw_cost) {
    cost = sample_draw_cost
    projectcost = sample_project.project_costs.change_requestable.order(created_at: :asc).first
    projectcost.total = 1000.0
    projectcost.save!
    sample_project.project_costs.reload
    cost.project_cost = projectcost
    cost.total = projectcost.total + 1.0
    cost.save!
    Invoice.create!(draw_cost: cost, user: user, amount: cost.total)
    cost.invoices.reload
    cost
  }
  let(:project_cost) { draw_cost.project_cost }
  let(:funding_source) { sample_project.project_costs.change_requestable.order(created_at: :asc).last }
  let(:user) { sample_project.developers.first }
  let(:unauthorized_user) { sample_project.investors.first }
  let(:valid_change_order_attributes) {
    raise 'error in test: funding source should be the same as the project cost' if funding_source.id == project_cost.id

    { description: 'Test description', funding_source_id: funding_source.id }
  }

  describe '#create' do
    describe 'as a developer' do
      it 'should create a change order' do
        sign_in user
        expect {
          post :create, params: {draw_cost_id: draw_cost.id, change_order: valid_change_order_attributes}
        }.to change{ChangeOrder.count}.by(1)
      end
    end
  end

  describe '#destroy' do
    it 'should delete the change order' do
      service = ChangeOrderService.new(user:, draw_cost:)
      change_order = service.create(valid_change_order_attributes)
      refute(service.errors?)
      sign_in user
      expect {
        delete :destroy, params: {draw_cost_id: draw_cost.id, id: change_order.id}
      }.to change{ChangeOrder.count}.by(-1)
    end
    it 'should not change the Draw state' do
      draw = draw_cost.draw
      service = ChangeOrderService.new(user:, draw_cost:)
      change_order = service.create(valid_change_order_attributes)
      refute(service.errors?)
      sign_in user
      expect {
        delete :destroy, params: {draw_cost_id: draw_cost.id, id: change_order.id}
        draw.reload
      }.to_not change{draw.state}
    end
  end
end
