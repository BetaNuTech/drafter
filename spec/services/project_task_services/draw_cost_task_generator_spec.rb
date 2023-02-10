require 'rails_helper'

RSpec.describe ProjectTaskServices::DrawCostTaskGenerator do
  include_context 'sample_draws'

  let(:service_class) { ProjectTaskServices::DrawCostTaskGenerator }
  let(:project) { sample_project }
  let(:draw) {project.draws.first }
  let(:draw_cost) {
    draw_cost2_invoices
    dc = draw_cost2
    dc.total = dc.invoice_total
    dc.state = 'submitted'
    dc.save!
    project_cost_id = dc.project_cost_id
    project_costs = sample_project.project_costs.drawable
    funding_source1 = project_costs.where.not(id: project_cost_id).sample
    funding_source2 = project_costs.where.not(id: [project_cost_id, funding_source1.id]).sample
    ChangeOrder.destroy_all
    ChangeOrder.create!(amount: 1500.0, description: 'CO #1',
                        draw_cost: dc,
                        project_cost_id: project_cost_id,
                        funding_source_id: funding_source1.id)
    dc.reload
    dc
  }
  let(:user) { project.developers.first }
  let(:assignee) { user }
  let(:valid_task_action) { :approve }
  let(:invalid_task_action) { :invalid_action }

  describe 'initialization' do
    it 'should initialize the generator with the approve action' do
      service = service_class.new(draw_cost: , assignee: assignee, action: valid_task_action)
      assert(service).is_a?(service_class)
    end
    it 'should throw an error if an invalid action is provided' do
      expect {
        service_class.new(draw_cost: , assignee: assignee, action: invalid_task_action)
      }.to raise_error(ProjectTaskServices::DrawCostTaskGenerator::Error)
    end
  end

  describe 'generating a task using the generate method' do
    it 'should create a new task for the draw cost and assignee' do
      service = service_class.new(draw_cost: draw_cost, assignee: assignee, action: valid_task_action)
      task = nil
      expect {
        task = service.generate
      }.to change{ProjectTask.count}
      project.reload
      assignee.reload

      expect(task.assignee).to eq(assignee)
      expect(task.origin).to eq(draw_cost)
      expect(task.project).to eq(project)
      expect(task.due_at).to be_a(Time)
      expect(task.name).to match('Approve')
      expect(task.name).to match(project.name)
      expect(assignee.assigned_tasks).to include(task)
      expect(project.project_tasks).to include(task)
    end
  end

  describe 'generating a task using the call class method' do
    it 'should create a new task for the draw cost and assignee' do
      task = nil
      expect {
        task = service_class.call(origin: draw_cost, assignee: assignee, action: valid_task_action)
      }.to change{ProjectTask.count}
      project.reload
      assignee.reload

      expect(task.assignee).to eq(assignee)
      expect(task.origin).to eq(draw_cost)
      expect(task.project).to eq(project)
      expect(task.due_at).to be_a(Time)
      expect(task.name).to match('Approve')
      expect(task.name).to match(project.name)
      expect(assignee.assigned_tasks).to include(task)
      expect(project.project_tasks).to include(task)
    end
  end

  describe 'attempting to create a project task that duplicates a visible project task' do
    it 'returns the original instead of creating a new project task' do
      initial_task_count = ProjectTask.count
      original_task = service_class.call(origin: draw_cost, assignee: assignee, action: valid_task_action)
      new_task = service_class.call(origin: draw_cost, assignee: assignee, action: valid_task_action)
      expect(ProjectTask.count).to eq(initial_task_count + 1)
    end
  end

end
