require 'rails_helper'

RSpec.describe DrawDocument, type: :model do
  include_context 'sample_projects'
  let(:user) { sample_project.developers.first }
  let(:approver) { sample_project.managers.first }
  let(:uploaded_file) {Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/sample_document_1.pdf", 'application/pdf')}
  let(:draw) { sample_project.draws.first}
  let(:draw_document) { DrawDocument.create!(draw: draw, user: user) }

  describe 'initialization' do
    it 'creates a DrawDocument' do
      draw_document = DrawDocument.new(draw: draw, user: user)
      assert(draw_document.save)
    end
  end

  describe 'state machine' do
    describe 'approval' do
      it 'approves a submitted document and assigns the approver' do
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
    describe 'withdrawal'
  end
  
end
