require 'rails_helper'

RSpec.describe DrawsController, type: :controller do
  include_context 'draw_service'
  render_views

  let(:valid_draw_attributes) { { amount: 1234.56, name: 'Draw 1', notes: 'Draw notes for test here' } }

  let(:project) { sample_project }
  before(:each) { project }

  describe '#new' do
    describe 'as a developer' do
      let(:user) { sample_project.developers.first }
      it 'should display the new draw form' do
        Draw.destroy_all
        sign_in user
        get :new, params: { project_id: project.id }
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#create' do
    describe 'as a developer' do
      let(:user) { project.developers.first }
      it 'should create a new draw for the project' do
        Draw.destroy_all
        sign_in user
        expect {
          post :create, params: {draw: valid_draw_attributes, project_id: project.id}
        }.to change{Draw.count}
        expect(response).to be_redirect
      end
    end
  end

  describe '#show' do
    describe 'as the project developer' do
      let(:user) { project.developers.first }
      let(:draw) { sample_draw }

      it 'should render the show template' do
        sign_in user
        get :show, params: {id: draw.id, project_id: project.id }
        expect(response).to render_template(:show)
      end
    end
  end

  describe '#edit' do
    describe 'as the project developer' do
      let(:user) { developer_user }
      let(:draw) { sample_draw }

      it 'should display the edit form' do
        sign_in user
        get :edit, params: {id: draw.id, project_id: project.id }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    let(:valid_attrs) { {amount: 777.77, name: 'New Name', notes: 'New notes'} }
    describe 'as the project developer' do
      let(:user) { developer_user }
      let(:draw) { sample_draw }
      it 'should update the draw' do
        sign_in user
        patch :update, params: {id: draw.id, project_id: project.id, draw: valid_attrs}
        expect(response).to be_redirect
        draw.reload
        expect(draw.amount).to eq(valid_attrs[:amount])
      end
    end
  end #update

  describe '#destroy' do
    describe 'as the project developer' do
      let(:user) { developer_user }
      let(:draw) { sample_draw }
      it 'should transition the draw to "withdrawn"' do
        sign_in user
        assert(draw.pending?)
        delete :destroy, params: { id: draw.id, project_id: project.id }
        expect(response).to be_redirect
        draw.reload
        assert(draw.withdrawn?)
      end
    end

  end #destroy

end
