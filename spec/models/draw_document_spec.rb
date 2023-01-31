# == Schema Information
#
# Table name: draw_documents
#
#  id           :uuid             not null, primary key
#  approved_at  :datetime
#  documenttype :integer          default("other"), not null
#  notes        :text
#  state        :string           default("pending")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  approver_id  :uuid
#  draw_id      :uuid             not null
#  user_id      :uuid
#
# Indexes
#
#  draw_documents_assoc_idx              (draw_id,user_id)
#  index_draw_documents_on_approver_id   (approver_id)
#  index_draw_documents_on_documenttype  (documenttype)
#  index_draw_documents_on_draw_id       (draw_id)
#  index_draw_documents_on_state         (state)
#  index_draw_documents_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_id => draws.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe DrawDocument, type: :model do
  include_context 'sample_projects'
  let(:user) { sample_project.developers.first }
  let(:approver) { sample_project.managers.first }
  let(:uploaded_file) {Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/sample_document_1.pdf", 'application/pdf')}
  let(:draw) {sample_project.draws.first}
  let(:draw_document) { DrawDocument.create!(draw: draw, user: user) }

  describe 'initialization' do
    it 'creates a DrawDocument' do
      draw_document = DrawDocument.new(draw: draw, user: user)
      assert(draw_document.save)
    end
  end

  describe 'state machine' do
    before do
      draw.state = 'submitted'
      draw.save!
    end
    describe 'approval' do
      it 'approves a submitted document and assigns the approver' do
        draw_document.draw.state = 'submitted'
        draw_document.draw.save!
        assert(draw_document.pending?)
        draw_document.trigger_event(event_name: :approve, user: approver)
        draw_document.reload
        assert(draw_document.approved?)
        expect(draw_document.approver).to eq(approver)
        assert(draw_document.approved_at.present?)
      end
    end
    describe 'rejection' do
      it 'rejects a pending document' do
        assert(draw_document.pending?)
        draw_document.trigger_event(event_name: :reject, user: approver)
        draw_document.reload
        refute(draw_document.approved?)
        refute(draw_document.approver.present?)
        refute(draw_document.approved_at.present?)
      end
      it 'rejects an approved document' do
        assert(draw_document.pending?)
        draw_document.trigger_event(event_name: :approve, user: approver)
        draw_document.reload
        assert(draw_document.approved?)
        expect(draw_document.approver).to eq(approver)
        draw_document.trigger_event(event_name: :reject, user: approver)
        draw_document.reload
        assert(draw_document.rejected?)
        refute(draw_document.approver.present?)
      end
    end
    describe 'withdrawal' do
      describe 'project tasks' do
        let(:completed_document_tasks) {
          Array.new(3) {
            task = ProjectTaskServices::Generator.call(origin: draw_document, action: :approve)
            task.state = 'approved'; task.save!
            task
          }
        }
        let(:pending_document_tasks) {
          Array.new(2) {
            task = ProjectTaskServices::Generator.call(origin: draw_document, action: :approve)
            task.state = 'needs_review'; task.save!
            task
          }
        }
        it 'archives pending tasks' do
          completed_document_tasks
          pending_document_tasks
          draw_document.project_tasks.reload
          expect(draw_document.project_tasks.pending.count).to eq(2)
          expect(draw_document.project_tasks.approved.count).to eq(3)
          task_count = draw_document.project_tasks.count
          draw_document.trigger_event(event_name: :withdraw)
          draw_document.project_tasks.reload
          expect(draw_document.project_tasks.count).to eq(task_count)
          expect(draw_document.project_tasks.approved.count).to eq(3)
          expect(draw_document.project_tasks.pending.count).to eq(0)
        end
      end
    end
  end
  
end
