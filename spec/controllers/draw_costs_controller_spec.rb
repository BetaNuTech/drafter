require 'rails_helper'

RSpec.describe DrawCostsController, type: :controller do
  include_context 'draw_service'
  render_views

  let(:valid_draw_cost_attributes) {
    {
      total: 1234.56,
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

  describe '#edit' do
    describe 'as a developer' do
      let(:user) { developer_user }
      let(:draw_cost) { sample_draw_cost }
      it 'should display the edit form' do
        sign_in user
        get :edit, params: {draw_id: draw_cost.draw_id, id: draw_cost.id}
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    let(:draw_cost) { sample_draw_cost }
    let(:new_draw_cost_attributes) { {total: draw_cost.total + 10.0 }}
    describe 'as a developer' do
      let(:user) { developer_user }
      it 'should update the draw_cost' do
        sign_in user
        patch :update, params: {draw_id: draw_cost.draw_id, id: draw_cost.id, draw_cost: new_draw_cost_attributes}
        expect(response).to be_redirect
        draw_cost.reload
        expect(draw_cost.total).to eq(new_draw_cost_attributes[:total])
      end
    end
  end

  describe '#destroy' do
    let(:draw_cost) { sample_draw_cost }
    describe 'as a developer' do
      let(:user) { developer_user }
      it 'should withdraw the draw_cost' do
        sign_in user
        assert(draw_cost.pending?)
        assert(draw_cost.draw_id.present?)
        delete :destroy, params: {draw_id: draw_cost.draw_id, id: draw_cost.id}
        expect(response).to be_redirect
        draw_cost.reload
        assert(draw_cost.withdrawn?)
      end
    end
  end

end
