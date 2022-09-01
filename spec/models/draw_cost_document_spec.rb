# == Schema Information
#
# Table name: draw_cost_documents
#
#  id                   :uuid             not null, primary key
#  approval_due_date    :date
#  approved_at          :datetime
#  documenttype         :integer          default("other"), not null
#  notes                :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  approver_id          :uuid
#  draw_cost_request_id :uuid             not null
#  user_id              :uuid
#
# Indexes
#
#  index_draw_cost_documents_on_approver_id           (approver_id)
#  index_draw_cost_documents_on_draw_cost_request_id  (draw_cost_request_id)
#  index_draw_cost_documents_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_cost_request_id => draw_cost_requests.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe DrawCostDocument, type: :model do
  include_context 'sample_projects'

  let(:developer_user) { sample_project.developers.first }
  let(:manager_user) { sample_project.managers.first }
  let(:valid_attributes) {
    {
      draw_cost_request: sample_draw_cost_request,
      user: developer_user,
      documenttype: :budget,
      notes: 'Document notes'
    }
  }

  describe 'initialization' do
    it 'can be initialized and saved' do
      expect {
        create(:draw_cost_document, valid_attributes)
      }.to change{DrawCostDocument.count}
    end
  end

  describe 'scopes' do
    it 'returns "other" documents' do
      doc = create(:draw_cost_document, valid_attributes.merge(documenttype: :other))
      expect(DrawCostDocument.other.first).to eq(doc)
    end
    it 'returns "budget" documents' do
      doc = create(:draw_cost_document, valid_attributes.merge(documenttype: :budget))
      expect(DrawCostDocument.budget.first).to eq(doc)
    end
    it 'returns "application" documents' do
      doc = create(:draw_cost_document, valid_attributes.merge(documenttype: :application))
      expect(DrawCostDocument.application.first).to eq(doc)
    end
    it 'returns "waiver" documents' do
      doc = create(:draw_cost_document, valid_attributes.merge(documenttype: :waiver))
      expect(DrawCostDocument.waiver.first).to eq(doc)
    end
  end # Scopes

  describe 'approvals' do
    let(:doc) {create(:draw_cost_document, valid_attributes.merge(documenttype: :other))}
    let(:user) { manager_user} 
    it 'can be approved by a user' do
      doc.approve(user)
      expect(doc.approver).to eq(user)
      assert(doc.approved_at.present?)
      assert(doc.approved?)
    end
  end # Approvals

  describe 'helper methods' do
    let(:doc) {create(:draw_cost_document, valid_attributes.merge(documenttype: :other))}
    it 'returns the document description based on the document type' do
      expect(doc.description).to eq(DrawCostDocument::OTHER_DESCRIPTION)
    end
  end # helpers

  describe 'document management' do
    let(:doc) {create(:draw_cost_document, valid_attributes.merge(documenttype: :other))}
    let(:file_upload) { fixture_file_upload('sample_document_1.pdf') }

    describe 'attachment' do
      it 'attaches a document' do
        doc.document.attach file_upload 
        assert(doc.document.attached?)
        url = doc.document.url
        assert(url.present?)
        preview_url = doc.document.preview(resize_to_limit: [500,500]).processed.url
        assert(preview_url).present?
      end

      describe 'with variants' do
        before do
          doc.document.attach file_upload 
        end
        it 'has a thumbnail' do
          url = doc.document.preview(resize_to_limit: [500,500]).processed.url
          assert(url.present?)
        end
      end
    end

    describe 'removing a document' do
      before do
        doc.document.attach file_upload 
      end
      it 'removes a document' do
        assert(doc.document.attached?)
        doc.document.purge
        doc.reload
        refute(doc.document.attached?)
      end
    end

  end

end

