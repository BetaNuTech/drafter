require 'rails_helper'

RSpec.describe ProjectsController, type: :controller do
  include_context 'users'
  include_context 'sample_projects'
  render_views

  let(:project) { sample_project }
  let(:user) { sample_project.managers.first }
  let(:nonproject_executive) { create(:user, role: executive_role) }
  let(:nonprivileged_user) { create(:user, role: user_role)}
  let(:valid_attributes) { {name: 'Test Project', description: 'This is a test project'}}
  let(:invalid_attributes) { {name: nil, description: 'This is a test project'}}

  describe '#create' do
    describe 'as an admin' do
      it 'should create a project' do
        sign_in nonproject_executive
        expect {
          post :create, params: {project: valid_attributes}
        }.to change{Project.count}
      end

    end
    describe 'as a non-privileged user' do
      it 'should not create a project' do
        sign_in nonprivileged_user
        expect {
          post :create, params: {project: valid_attributes}
        }.to_not change{Project.count}
      end
    end
  end # #create

  describe '#edit' do 
    describe 'as an admin' do
      it 'should show the project form' do
        sign_in nonproject_executive
        get :edit, params: {id: sample_project.id}
        expect(response).to render_template(:edit)
      end

    end
    describe 'as a non-privileged user' do
      it 'should not show the edit form' do
        sign_in nonprivileged_user
        get :edit, params: {id: sample_project.id}
        expect(response).to be_redirect
      end
    end
  end # #edit

  describe '#update' do
    let(:new_attributes) { {name: 'ZZZ' }}
    describe 'as an admin' do
      it 'should update the project information' do
        sign_in nonproject_executive
        expect {
          patch :update, params: { id: sample_project.id, project: new_attributes}
          sample_project.reload
        }.to change{sample_project.name}
      end
    end
    describe 'as a project owner' do
      it 'should update the project information' do
        sign_in sample_project.owners.first
        expect {
          patch :update, params: { id: sample_project.id, project: new_attributes}
          sample_project.reload
        }.to change{sample_project.name}
      end
    end
    describe 'as a project manager' do
      it 'should update the project information' do
        sign_in sample_project.managers.first
        expect {
          patch :update, params: { id: sample_project.id, project: new_attributes}
          sample_project.reload
        }.to change{sample_project.name}
      end
    end
    describe 'as a non-privileged project user' do
      it 'should not update the project information' do
        sign_in sample_project.developers.first
        expect {
          patch :update, params: { id: sample_project.id, project: new_attributes}
          sample_project.reload
        }.to_not change{sample_project.name}
      end
    end
    describe 'as a non-privileged user' do
      it 'should not update the project information' do
        sign_in nonprivileged_user
        expect {
          patch :update, params: { id: sample_project.id, project: new_attributes}
          sample_project.reload
        }.to_not change{sample_project.name}
      end
    end
  end # #update

  describe '#show' do
    describe 'as an project member' do
      it 'should show the project page' do
        sign_in user
        get :show, params: { id: sample_project.id }
        expect(response).to render_template(:show)
      end
    end
    describe 'as an executive who is not a project member' do
      it 'should show the project page' do
        sign_in nonproject_executive
        get :show, params: { id: sample_project.id }
        expect(response).to render_template(:show)
      end
    end
    describe 'as a non-privileged user' do
      it 'should redirect' do
        sign_in nonprivileged_user
        get :show, params: { id: sample_project.id }
        expect(response).to be_redirect
      end
    end
  end

  describe '#destroy' do
    describe 'as an admin' do
      it 'should delete the project' do
        sign_in admin_user
        expect {
          delete :destroy, params: {id: sample_project.id}
        }.to change{Project.count}.by(-1)
      end
    end
    describe 'as a project owner' do
      it 'should delete the project' do
        sign_in sample_project.owners.first
        expect {
          delete :destroy, params: {id: sample_project.id}
        }.to change{Project.count}.by(-1)
      end
    end
    describe 'as a project manager' do
      it 'should not delete the project' do
        sign_in sample_project.managers.first
        expect {
          delete :destroy, params: {id: sample_project.id}
        }.to_not change{Project.count}
      end
    end
    describe 'as a non-privileged project user' do
      it 'should not delete the project' do
        sign_in sample_project.finance.first
        expect {
          delete :destroy, params: {id: sample_project.id}
        }.to_not change{Project.count}
      end
    end
    describe 'as a non-privileged user' do
      it 'should not delete the project' do
        sign_in nonprivileged_user
        expect {
          delete :destroy, params: {id: sample_project.id}
        }.to_not change{Project.count}
      end
    end
  end

end
