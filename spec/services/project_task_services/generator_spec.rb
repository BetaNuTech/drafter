require 'rails_helper'

RSpec.describe ProjectTaskServices::Generator do
  include_context 'sample_draws'

  let(:service_class) { ProjectTaskServices::Generator }
  let(:project) { sample_project }
  let(:draw) {project.draws.first}
  let(:draw_document) { DrawDocument.create!(draw: draw, user: user, document: uploaded_file) }
  let(:invoice) {
    invoices = draw_cost_invoices
    invoice = invoices.first
    invoice.annotated_preview = uploaded_file
    invoice.state = 'submitted'
    invoice.save
    invoice
  }
  let(:user) { project.developers.first }
  let(:assignee) { user }
  let(:valid_task_action) { :approve }
  let(:invalid_task_action) { :invalid_action }

  describe 'calling the generator service' do
    describe 'with an invoice' do
      it 'creates a task for approving the invoice' do
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
        expect(task.name).to match('Approve')
        expect(task.name).to match(project.name)
        expect(task.description).to match('active_storage')
        expect(assignee.assigned_tasks).to include(task)
        expect(project.project_tasks).to include(task)
      end
    end

    describe 'with a draw document' do
      it 'creates a task for approving the draw document' do
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
        expect(task.name).to match('Approve')
        expect(task.name).to match(project.name)
        expect(task.description).to match('active_storage')
        expect(assignee.assigned_tasks).to include(task)
        expect(project.project_tasks).to include(task)
      end
    end

  end
end
