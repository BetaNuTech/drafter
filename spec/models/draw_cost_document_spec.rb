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
end

