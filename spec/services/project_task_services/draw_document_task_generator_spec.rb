require 'rails_helper'

RSpec.describe ProjectTaskServices::DrawDocumentTaskGenerator do
  include_context 'sample_draws'

  let(:service_class) { ProjectTaskServices::DrawDocumentTaskGenerator }
  let(:project) { sample_project }
  let(:draw) {project.draws.first}
  let(:draw_document) { DrawDocument.create!(draw: draw, user: user, document: uploaded_file) }
  let(:user) { project.developers.first }
  let(:assignee) { user }
  let(:valid_task_action) { :verify }
  let(:invalid_task_action) { :invalid_action }

  describe 'initialization' do
    it 'should initialize the generator with the verify action' do
      service = service_class.new(draw_document: draw_document, assignee: assignee, action: valid_task_action)
      assert(service).is_a?(service_class)
    end
    it 'should throw an error if an invalid action is provided' do
      expect {
        service_class.new(draw_document: draw_document, assignee: assignee, action: invalid_task_action)
      }.to raise_error(ProjectTaskServices::DrawDocumentTaskGenerator::Error)
    end
  end

  describe 'generating a task using the generate method' do
    it 'should create a new task for the draw document and assignee' do
      service = service_class.new(draw_document: draw_document, assignee: assignee, action: valid_task_action)
      task = nil
      expect {
        task = service.generate
      }.to change{ProjectTask.count}
      project.reload
      assignee.reload

      expect(task.assignee).to eq(assignee)
      expect(task.origin).to eq(draw_document)
      expect(task.project).to eq(project)
      expect(task.due_at).to be_a(Time)
      assert(task.attachment_url.present?)
      expect(task.name).to match('Verify')
      expect(task.name).to match(project.name)
      expect(task.description).to match('active_storage')
      expect(assignee.assigned_tasks).to include(task)
      expect(project.project_tasks).to include(task)
    end
  end

  describe 'generating a task using the call class method' do
    it 'should create a new task for the draw_document and assignee' do
      task = nil
      expect {
        task = service_class.call(origin: draw_document, assignee: assignee, action: valid_task_action)
      }.to change{ProjectTask.count}
      project.reload
      assignee.reload

      expect(task.assignee).to eq(assignee)
      expect(task.origin).to eq(draw_document)
      expect(task.project).to eq(project)
      expect(task.due_at).to be_a(Time)
      assert(task.attachment_url.present?)
      expect(task.name).to match('Verify')
      expect(task.name).to match(project.name)
      expect(task.description).to match('active_storage')
      expect(assignee.assigned_tasks).to include(task)
      expect(project.project_tasks).to include(task)
    end
  end

end
