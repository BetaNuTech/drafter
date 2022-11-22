require 'rails_helper'

RSpec.describe ProjectCostsController, type: :controller do
  include_context 'sample_projects'
  render_views

  let(:project) { sample_project }
  let(:user) { sample_project.managers.first }
  let(:valid_params) {
    {
      approval_lead_time: 10,
      name: 'Test Cost',
      cost_type: :soft,
      total: 10000.0
    }
  }
  let(:invalid_params) { valid_params.merge({total: -1.0}) }
  
  describe '#create' do
    describe 'as a manager' do
      let(:draw) { sample_draw }
      describe 'before the first draw is approved' do
        it 'creates a project cost' do
          assert(project.allow_project_cost_changes?)
          sign_in user
          expect {
            post :create, params: {project_id: project.id, project_cost: valid_params}
          }.to change{ProjectCost.count}
        end
      end
      describe 'after the first draw is approved' do
        it 'will not be created' do
          assert(project.allow_project_cost_changes?)
          draw = create(:draw, project:, state: 'internally_approved', index: 10)
          project.reload
          refute(project.allow_project_cost_changes?)
          sign_in user
          expect {
            post :create, params: {project_id: project.id, project_cost: valid_params}
          }.to_not change{ProjectCost.count}
        end
      end
    end
  end

  describe '#update' do
    describe 'as a manager' do
      let(:draw) { sample_draw }
      let(:project_cost) { project.project_costs.drawable.first }
      describe 'before the first draw is approved' do
        it 'updates the project cost' do
          assert(project.allow_project_cost_changes?)
          sign_in user
          expect {
            put :update, params: {project_id: project.id, id: project_cost.id, project_cost: {total: 999.0}}
            project_cost.reload
          }.to change{project_cost.total}
        end
      end
      describe 'after the first draw is approved' do
        it 'will not update the project cost' do
          assert(project.allow_project_cost_changes?)
          draw = create(:draw, project:, state: 'internally_approved', index: 10)
          project.reload
          refute(project.allow_project_cost_changes?)
          sign_in user
          expect {
            put :update, params: {project_id: project.id, id: project_cost.id, project_cost: {total: 9999.0}}
            project_cost.reload
          }.to_not change{project_cost.total}
        end
      end
    end
  end
  
end
