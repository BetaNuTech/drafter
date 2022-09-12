require 'rails_helper'

RSpec.describe DrawCostRequestsController, type: :controller do
  include_context 'sample_projects'
  render_views

  let(:owner_user) {sample_project.owners.first}
  let(:developer_user) { sample_project.developers.first }
  let(:consultant_user) { sample_project.consultants.first }
  let(:draw) { sample_draw }
  let(:project) { sample_project }
  let(:draw_cost) { sample_draw_cost }
  let(:valid_attributes) {
    {
      draw_id: draw.id,
      draw_cost_request: {
        draw_id: draw.id,
        draw_cost_id: draw_cost.id,
        amount: 1234.56,
        plan_change: true,
        plan_change_reason: 'Test Reason'
      }
    }
  }
  let(:invalid_attributes) {
    {
      draw_id: draw.id,
      draw_cost_request: {
        draw_id: draw.id,
        draw_cost_id: draw_cost.id,
        amount: nil,
        plan_change: true,
        plan_change_reason: 'Test Reason'
      }
    }
  }
  let(:invalid_attributes_wo_draw_cost) {
    {
      draw_id: draw.id,
      draw_cost_request: {
        draw_id: draw.id,
        draw_cost_id: nil,
        amount: 1234.56,
        plan_change: true,
        plan_change_reason: 'Test Reason'
      }
    }
  }

  before(:each) { sample_project }
  describe 'when unauthenticated' do
    it 'should redirect to login' do
      get :index, params: {draw_id: draw.id}
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe '#new' do
    describe 'as an owner' do
      let(:user) { owner_user }
      it 'should display the new draw cost page' do
        sign_in user
        get :new, params: {draw_id: draw.id }
        expect(response).to render_template(:new)
      end
    end
    describe 'as a developer' do
      let(:user) { developer_user }
      it 'should display the new draw cost page' do
        sign_in user
        get :new, params: {draw_id: sample_draw.id }
        expect(assigns[:draw]).to eq(sample_draw)
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#create' do
    describe 'as an owner' do
      let(:user) { owner_user }
      before(:each) { sign_in user }
      describe 'with valid attributes' do
        it 'creates the request' do
          expect {
            post :create, params: valid_attributes
          }.to change{DrawCostRequest.count}
          dcr = assigns(:draw_cost_request)
          assert(dcr.present?)
          expect(dcr.draw).to eq(draw)
          expect(dcr.draw_cost).to eq(draw_cost)
        end
      end
    end
    describe 'as a developer' do
      let(:user) { developer_user }
      before(:each) { sign_in user }
      describe 'with valid attributes' do
        it 'creates the request' do
          expect {
            post :create, params: valid_attributes
          }.to change{DrawCostRequest.count}
          dcr = assigns(:draw_cost_request)
          assert(dcr.present?)
          expect(dcr.draw).to eq(draw)
          expect(dcr.draw_cost).to eq(draw_cost)
        end
      end
      describe 'with invalid attributes' do
        it 'does not create the request' do
          expect {
            post :create, params: invalid_attributes
          }.to_not change{DrawCostRequest.count}
          dcr = assigns(:draw_cost_request)
          assert(dcr.invalid?)
        end
      end
    end
    describe 'as disallowed user' do
      let(:user) { consultant_user }
      before(:each) { sign_in user }
      it 'does not create the request' do
          expect {
            post :create, params: valid_attributes
          }.to_not change{DrawCostRequest.count}
          dcr = assigns(:draw_cost_request)
          assert(dcr.invalid?)
      end
    end
  end
end
