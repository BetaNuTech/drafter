require 'rails_helper'

RSpec.describe ChangeOrdersController, type: :controller do
  include_context 'sample_projects'
  render_views

  let(:project) { sample_project }
  let(:draw_cost) {
    cost = sample_draw_cost
    cost.project_cost = sample_project.project_costs.first
    cost.save!
    Invoice.create!(draw_cost: cost, user: user, amount: ( cost.total + 1.0 ))
    cost.invoices.reload
    cost
  }
  let(:project_cost) { draw_cost.project_cost }
  let(:funding_source) { sample_project.project_costs.last }
  let(:user) { sample_project.developers.first }
  let(:unauthorized_user) { sample_project.investors.first }
  let(:valid_change_order_attributes) {
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
      change_order = ChangeOrderService.new(user:, draw_cost:).create(valid_change_order_attributes)
      sign_in user
      expect {
        delete :destroy, params: {draw_cost_id: draw_cost.id, id: change_order.id}
      }.to change{ChangeOrder.count}.by(-1)
    end
  end
end
