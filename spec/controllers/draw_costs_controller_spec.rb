require 'rails_helper'

RSpec.describe DrawCostsController, type: :controller do
  include_context 'draw_service'
  render_views

  let(:valid_draw_cost_attributes) {
    {
      total: 1234.56,
      contingency: 345.67,
      plan_change: true,
      plan_change_reason: 'Test reason',
      project_cost_id: sample_project_cost.id
    }
  }
  let(:draw) { sample_draw }

  before(:each) { sample_project }

  describe '#new' do
    describe 'as a developer' do
      let(:user) { developer_user }
      it 'should display the new form' do
        sign_in user
        get :new, params: {draw_id: draw.id }
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#create' do
    describe 'as a developer' do
      let(:user) { developer_user }
      it 'should create a new draw cost' do
        sign_in user
        expect {
          post :create, params: {draw_id: draw.id, draw_cost: valid_draw_cost_attributes}
        }.to change{DrawCost.count}
        expect(response).to be_redirect
      end
    end
  end
end
