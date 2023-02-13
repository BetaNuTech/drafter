# == Schema Information
#
# Table name: project_tasks
#
#  id                     :uuid             not null, primary key
#  approver_name          :string
#  assignee_name          :string
#  attachment_url         :string
#  completed_at           :datetime
#  description            :text             not null
#  due_at                 :datetime
#  name                   :string           not null
#  notes                  :text
#  origin_type            :string
#  preview_url            :string
#  remote_last_checked_at :datetime
#  remote_updated_at      :datetime
#  remoteid               :string
#  reviewed_at            :datetime
#  state                  :string           default("new"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  approver_id            :uuid
#  assignee_id            :uuid
#  origin_id              :uuid
#  project_id             :uuid             not null
#
# Indexes
#
#  idx_project_tasks_general           (project_id,assignee_id,approver_id,state)
#  idx_project_tasks_origin            (origin_type,origin_id)
#  idx_project_tasks_remote            (remoteid,remote_updated_at,remote_last_checked_at)
#  index_project_tasks_on_approver_id  (approver_id)
#  index_project_tasks_on_assignee_id  (assignee_id)
#  index_project_tasks_on_origin       (origin_type,origin_id)
#  index_project_tasks_on_project_id   (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (project_id => projects.id)
#
require 'rails_helper'

RSpec.describe ProjectTask, type: :model do
  include_context 'sample_draws'

  before(:each) {
    invoices
    sample_project.reload
  }

  let(:sample_project_task) {
    assignee = sample_project.developers.first
    build(:project_task,
            project: sample_project,
            origin: invoices.first,
            assignee: assignee,
            assignee_name: assignee.name
       )
  }

  describe 'initialization' do
    let(:object) { sample_project_task }
    it 'initializes a ProjectTask' do
      assert(object.save)
    end
  end # End initialization test

  describe 'validations' do
    let(:object) { sample_project_task }

    it 'validates the presence of name' do
      assert(object.valid?)
      object.name = nil
      refute(object.valid?)
    end

    it 'validates the presence of description' do
      assert(object.valid?)
      object.description = nil
      refute(object.valid?)
    end
  end # End validations test

  describe 'origin state machines' do
    describe 'bubbling events to task' do
      let(:invoice) { draw_cost_invoices.first }
      let(:invoice_task) {
        task = ProjectTaskService.new.generate(origin: invoice, action: :approve)
        task.update(state: :needs_review)
        task
      }
      let(:draw_document) { draw_documents.first }
      let(:draw_document_task) {
        task = ProjectTaskService.new.generate(origin: draw_document, action: :approve)
        task.update(state: :needs_review)
        task
      }
      let(:draw_task) {
        task = ProjectTaskService.new.generate(origin: draw, action: :approve)
        task.update(state: :needs_review)
        task
      }
      let(:draw_cost_task) {
        task = ProjectTaskService.new.generate(origin: draw_cost, action: :approve)
        task.update(state: :needs_review)
        task
      }

      before do
        draw.update(state: :submitted)
        draw_cost.update(state: :submitted)
        draw_cost.invoices.update(state: :approved)
        invoice.update(state: :submitted)
      end

      it 'should accept the task on invoice approve' do
        invoice_task
        invoice.reload
        invoice.trigger_event(event_name: :approve)
        invoice_task.reload
        expect(invoice_task.state).to eq('approved')
      end
      it 'should reject the task on invoice reject' do
        invoice_task
        invoice.reload
        invoice.trigger_event(event_name: :reject)
        invoice_task.reload
        expect(invoice_task.state).to eq('rejected')
      end
      it 'should archive the task on invoice remove' do
        invoice_task
        invoice.reload
        invoice.update(state: :rejected)
        invoice.draw_cost.update(state: :rejected)
        invoice.draw.update(state: :rejected)
        invoice.reload
        invoice.trigger_event(event_name: :remove)
        invoice_task.reload
        expect(invoice_task.state).to eq('archived')
      end
      it 'should accept the task on draw document approve' do
        draw_document_task
        draw_document.reload
        draw_document.trigger_event(event_name: :approve)
        draw_document_task.reload
        expect(draw_document_task.state).to eq('approved')
      end
      it 'should reject the task on draw document reject' do
        draw_document_task
        draw_document.reload
        draw_document.trigger_event(event_name: :reject)
        draw_document_task.reload
        expect(draw_document_task.state).to eq('rejected')
      end
      it 'should archive the task on draw document withdraw' do
        draw_document_task
        draw_document.reload
        draw_document.trigger_event(event_name: :withdraw)
        draw_document_task.reload
        expect(draw_document_task.state).to eq('archived')
      end
      it 'should accept the task on draw approve' do
        draw_documents
        draw_task
        draw.draw_costs.update(state: :approved)
        draw.draw_documents.update(state: :approved)
        draw.reload
        draw.trigger_event(event_name: :approve)
        draw_task.reload
        expect(draw_task.state).to eq('approved')
      end
      it 'should reject the task on draw reject' do
        draw_task
        draw.reload
        draw.trigger_event(event_name: :reject)
        draw_task.reload
        expect(draw_task.state).to eq('rejected')
      end
      it 'should archive the task on draw withdraw' do
        draw_task
        draw.reload
        draw.trigger_event(event_name: :withdraw)
        draw_task.reload
        expect(draw_task.state).to eq('archived')
      end
      it 'should accept the task on draw_cost approve' do
        draw_cost_task
        draw_cost.reload
        draw_cost.trigger_event(event_name: :approve)
        draw_cost_task.reload
        expect(draw_cost_task.state).to eq('approved')
      end
      it 'should reject the task on draw_cost reject' do
        draw_cost_task
        draw_cost.reload
        draw_cost.trigger_event(event_name: :reject)
        draw_cost_task.reload
        expect(draw_cost_task.state).to eq('rejected')
      end
      it 'should archive the task on draw_cost remove' do
        draw_cost_task
        draw_cost.reload
        draw_cost.trigger_event(event_name: :withdraw)
        draw_cost_task.reload
        expect(draw_cost_task.state).to eq('archived')
      end
    end
  end

end
