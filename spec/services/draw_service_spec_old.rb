require 'rails_helper'


RSpec.describe Projects::DrawService do
  include_context 'users'
  include_context 'sample_projects'

  let(:project) { sample_project }
  let(:user) { project.owners.first }
  let(:draw) { project.draws.first }
  let(:admin_user) { create(:user, role: admin_role) }
  let(:owner_user) { project.owners.first }
  let(:manager_user) { project.managers.first }
  let(:developer_user) { project.developers.first }
  let(:non_project_user) { create(:user, role: user_role) }
  let(:valid_attributes) { { name: 'Test Draw', notes: 'Test notes' } }
  let(:invalid_attributes) { { name: nil, notes: 'Test notes' } }

  describe 'initialization' do
    it 'should initialize the service without a draw' do
      service = Projects::DrawService.new(current_user: user, project: project)
    end
    it 'should initialize the service with a draw' do
      service = Projects::DrawService.new(current_user: user, project: project, draw: draw)
      expect(service.draw).to eq(draw)
    end
    it 'should initialize the service with a draw id' do
      service = Projects::DrawService.new(current_user: user, project: project, draw: draw.id)
      expect(service.draw).to eq(draw)
    end

  end

  describe 'creating a draw' do

    describe 'by project management' do
      it 'should create a new draw if provided valid attributes' do
        user = owner_user
        service = Projects::DrawService.new(current_user: user, project: project)
        expect {
          service.create(valid_attributes)
        }.to change{Draw.count}
        refute(service.errors?)
      end
      it 'should not create a new draw if not provided valid attributes' do
        user = owner_user
        service = Projects::DrawService.new(current_user: user, project: project)
        expect {
          service.create(invalid_attributes)
          project.reload
        }.to_not change{Draw.count}
        assert(service.errors?)
      end
    end
    describe 'by an unprivileged project user' do
      it 'should not create a new draw if provided valid attributes' do
        user = developer_user
        service = Projects::DrawService.new(current_user: user, project: project)
        expect {
          service.create(valid_attributes)
        }.to raise_error Projects::DrawService::PolicyError
      end
    end
    describe 'by a user not assigned to the project' do
      it 'should not create a new draw if provided valid attributes' do
        user = create(:user, role: user_role)
        service = Projects::DrawService.new(current_user: user, project: project)
        expect {
          service.create(valid_attributes)
        }.to raise_error Projects::DrawService::PolicyError

        user = create(:user, role: executive_role)
        service = Projects::DrawService.new(current_user: user, project: project)
        expect {
          service.create(valid_attributes)
        }.to raise_error Projects::DrawService::PolicyError
      end
    end 
  end # Create draw

  describe 'updating a draw' do
    let(:valid_updated_attributes) { { name: 'New Test Name'} }
    let(:invalid_updated_attributes) { { name: ''} }
    describe 'by an admin' do
      it 'should update the draw' do
        service = Projects::DrawService.new(current_user: admin_user, project: project, draw: draw)
        service.update(valid_updated_attributes)
        draw.reload
        expect(draw.name).to eq(valid_updated_attributes[:name])
      end

      describe 'with invalid attributes' do
        it 'should not update the draw' do
          service = Projects::DrawService.new(current_user: admin_user, project: project, draw: draw)
          original_name = draw.name
          service.update(invalid_updated_attributes)
          draw.reload
          expect(draw.name).to eq(original_name)
        end
      end
    end
    describe 'by project management' do
      it 'should update the draw' do
        service = Projects::DrawService.new(current_user: manager_user, project: project, draw: draw)
        service.update(valid_updated_attributes)
        draw.reload
        expect(draw.name).to eq(valid_updated_attributes[:name])
      end
    end
    describe 'by an unprivileged project user' do
      it 'should not update the draw' do
        service = Projects::DrawService.new(current_user: developer_user, project: project, draw: draw)
        expect {
          service.update(valid_updated_attributes)
        }.to raise_error Projects::DrawService::PolicyError
      end
    end
    describe 'by user not assigned to the project' do
      it 'should not update the draw' do
        service = Projects::DrawService.new(current_user: non_project_user, project: project, draw: draw)
        expect {
          service.update(valid_updated_attributes)
        }.to raise_error Projects::DrawService::PolicyError
      end
    end
  end

  describe 'destroying a draw' do
    describe 'by an admin' do
      it 'should destroy the draw' do
        service = Projects::DrawService.new(current_user: admin_user, project: project, draw: draw)
        expect {
          service.destroy
        }.to change{Draw.count}
      end
    end
    describe 'by the project owner' do
      it 'should destroy the draw' do
        service = Projects::DrawService.new(current_user: owner_user, project: project, draw: draw)
        expect {
          service.destroy
        }.to change{Draw.count}
      end
    end
    describe 'by a manager' do
      it 'should not destroy the draw' do
        service = Projects::DrawService.new(current_user: manager_user, project: project, draw: draw)
        draw_count = Draw.count
        expect {
          service.destroy
        }.to raise_error Projects::DrawService::PolicyError
        expect(Draw.count).to eq(draw_count)
      end
    end
    describe 'by an unprivileged project user' do
      it 'should not destroy the draw' do
        service = Projects::DrawService.new(current_user: developer_user, project: project, draw: draw)
        draw_count = Draw.count
        expect {
          service.destroy
        }.to raise_error Projects::DrawService::PolicyError
        expect(Draw.count).to eq(draw_count)
      end
    end
    describe 'by a user not assigned to the project' do
      it 'should not destroy the draw' do
        service = Projects::DrawService.new(current_user: non_project_user, project: project, draw: draw)
        draw_count = Draw.count
        expect {
          service.destroy
        }.to raise_error Projects::DrawService::PolicyError
        expect(Draw.count).to eq(draw_count)
      end
    end
  end # Destroy draw
end
