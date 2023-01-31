require 'rails_helper'

RSpec.describe ProjectTaskServices::InvoiceTaskGenerator do
  include_context 'sample_draws'

  let(:service_class) { ProjectTaskServices::InvoiceTaskGenerator }
  let(:project) { sample_project }
  let(:invoice) {
    invoices = draw_cost_invoices
    invoice = invoices.first
    invoice.annotated_preview = uploaded_file
    invoice.state = 'submitted'
    invoice.save
    invoice
  }
  let(:assignee) { project.developers.first }
  let(:valid_task_action) { :approve }
  let(:invalid_task_action) { :invalid_action }

  describe 'initialization' do
    it 'should initialize the generator with the approve action' do
      service = service_class.new(invoice: invoice, assignee: assignee, action: valid_task_action)
      assert(service).is_a?(service_class)
    end

    it 'should throw an error if an invalid action is provided' do
      expect {
        service_class.new(invoice: invoice, assignee: assignee, action: invalid_task_action)
      }.to raise_error(ProjectTaskServices::InvoiceTaskGenerator::Error)
    end
  end

  describe 'generating a task using the generate method' do
    it 'should create a new task for the invoice and assignee' do
      service = service_class.new(invoice: invoice, assignee: assignee, action: valid_task_action)
      task = nil
      expect {
        task = service.generate
      }.to change{ProjectTask.count}
      project.reload
      assignee.reload

      expect(task.assignee).to eq(assignee)
      expect(task.origin).to eq(invoice)
      expect(task.project).to eq(project)
      expect(task.due_at).to be_a(Time)
      assert(task.attachment_url.present?)
      assert(task.preview_url.present?)
      expect(task.name).to match('Approve')
      expect(task.name).to match(project.name)
      expect(task.description).to match('active_storage')
      expect(assignee.assigned_tasks).to include(task)
      expect(project.project_tasks).to include(task)
    end
  end

  describe 'generating a task using the call class method' do
    it 'should create a new task for the invoice and assignee' do
      task = nil
      expect {
        task = service_class.call(origin: invoice, assignee: assignee, action: valid_task_action)
      }.to change{ProjectTask.count}
      project.reload
      assignee.reload

      expect(task.assignee).to eq(assignee)
      expect(task.origin).to eq(invoice)
      expect(task.project).to eq(project)
      expect(task.due_at).to be_a(Time)
      assert(task.attachment_url.present?)
      assert(task.preview_url.present?)
      expect(task.name).to match('Approve')
      expect(task.name).to match(project.name)
      expect(task.description).to match('active_storage')
      expect(assignee.assigned_tasks).to include(task)
      expect(project.project_tasks).to include(task)
    end
  end

end
