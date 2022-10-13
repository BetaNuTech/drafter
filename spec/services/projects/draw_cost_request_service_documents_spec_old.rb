require 'rails_helper'

RSpec.describe Projects::DrawCostRequestService do
  include_context 'draw_cost_request_service'

  describe 'documents' do
    let(:draw_cost_request) {
      service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost: draw_cost)
      dcr = service.create_request(valid_draw_cost_request_attributes)
      dcs = dcr.draw_cost_submissions.first
      dcs.update(state: :submitted, amount: 1.0)
      dcr.reload
      dcr
    }
    let(:file_upload) { fixture_file_upload('sample_document_1.pdf') }
    let(:document_attributes) {
      { documenttype: 'budget', document: file_upload }
    }
    let(:draw_cost_document) {
      service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost_request: draw_cost_request)
      doc = service.add_document(document_attributes)
      draw_cost_request.draw_cost_documents.reload
      doc
    }

    describe 'upload' do
      describe 'by the developer' do
        describe 'with an invalid document type' do
          let(:invalid_document_attributes) { document_attributes.merge(documenttype: 'invalid')}
          it 'does not add the document' do
            service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost_request: draw_cost_request)
            assert(draw_cost_request.draw_cost_documents.empty?)
            draw_cost_document = nil
            expect {
              draw_cost_document = service.add_document(invalid_document_attributes)
              draw_cost_request.draw_cost_documents.reload
            }.to_not change{draw_cost_request.draw_cost_documents.count}
            assert(service.errors?)
          end
        end
        describe 'with valid attributes' do
          it 'is added' do
            service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost_request: draw_cost_request)
            assert(draw_cost_request.draw_cost_documents.empty?)
            draw_cost_document = nil
            expect {
              draw_cost_document = service.add_document(document_attributes)
              draw_cost_request.draw_cost_documents.reload
            }.to change{draw_cost_request.draw_cost_documents.count}.by(1)
            refute(service.errors?)
            assert(draw_cost_document.id.present?)
            draw_cost_request.draw_cost_documents.reload
            expect(draw_cost_request.draw_cost_documents.budget.last).to eq(draw_cost_document)
          end
        end
      end # by developer
      describe 'by an authorized user' do
        it 'is added' do
            service = Projects::DrawCostRequestService.new(user: owner_user, draw_cost_request: draw_cost_request)
            assert(draw_cost_request.draw_cost_documents.empty?)
            draw_cost_document = nil
            expect {
              draw_cost_document = service.add_document(document_attributes)
              draw_cost_request.draw_cost_documents.reload
            }.to change{draw_cost_request.draw_cost_documents.count}.by(1)
            refute(service.errors?)
            assert(draw_cost_document.id.present?)
            draw_cost_request.draw_cost_documents.reload
            expect(draw_cost_request.draw_cost_documents.budget.last).to eq(draw_cost_document)
        end
      end # by authorized user
      describe 'by an unauthorized user' do
        it 'throws an error' do
          service = Projects::DrawCostRequestService.new(user: finance_user, draw_cost_request: draw_cost_request)
          expect {
            draw_cost_document = service.add_document(document_attributes)
          }.to raise_error(Projects::DrawCostRequestService::PolicyError)
        end
      end # by unauthorized user
    end # Add Document

    describe 'remove document' do
      describe 'by the developer' do
        it 'is removed' do
          service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost_request: draw_cost_request)
          draw_cost_document
          expect {
            service.remove_document(draw_cost_document)
            draw_cost_request.draw_cost_documents.reload
          }.to change{draw_cost_request.draw_cost_documents.count}.by(-1)
        end
      end
      describe 'by an authorized user' do
        it 'is removed' do
          service = Projects::DrawCostRequestService.new(user: owner_user, draw_cost_request: draw_cost_request)
          draw_cost_document
          expect {
            service.remove_document(draw_cost_document)
            draw_cost_request.draw_cost_documents.reload
          }.to change{draw_cost_request.draw_cost_documents.count}.by(-1)
        end
      end
      describe 'by an unauthorized user' do
        it 'throws an error' do
          service = Projects::DrawCostRequestService.new(user: finance_user, draw_cost_request: draw_cost_request)
          draw_cost_document
          count = DrawCostDocument.count
          expect {
            service.remove_document(draw_cost_document)
            draw_cost_request.draw_cost_documents.reload
          }.to raise_error(Projects::DrawCostRequestService::PolicyError)
          expect(DrawCostDocument.count).to eq(count)
        end
      end
    end # Remove document

    describe 'approve document' do
      describe 'by an authorized user' do
        it 'is approved' do
          refute(draw_cost_document.approved?)
          service = Projects::DrawCostRequestService.new(user: manager_user, draw_cost_request: draw_cost_request)
          service.approve_document(draw_cost_document)
          draw_cost_document.reload
          assert(draw_cost_document.approved?)
        end
      end
      describe 'by an unauthorized user' do
        it 'throws an error' do
          service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost_request: draw_cost_request)
          expect {
            service.approve_document(draw_cost_document)
          }.to raise_error(Projects::DrawCostRequestService::PolicyError)
          draw_cost_document.reload
          refute(draw_cost_document.approved?)
        end
      end
    end # Approve document

    describe 'reject document' do
      before do
        draw_cost_document.approve(manager_user)
      end
      describe 'by an authorized user' do
        it 'is rejected' do
          assert(draw_cost_document.approved?)
          service = Projects::DrawCostRequestService.new(user: manager_user, draw_cost_request: draw_cost_request)
          service.reject_document(draw_cost_document)
          draw_cost_document.reload
          refute(draw_cost_document.approved?)
        end
      end
      describe 'by an unauthorized user' do
        it 'throws an error' do
          service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost_request: draw_cost_request)
          expect {
            service.reject_document(draw_cost_document)
          }.to raise_error(Projects::DrawCostRequestService::PolicyError)
          draw_cost_document.reload
          assert(draw_cost_document.approved?)
        end
      end
    end # Reject document
  end # Documents

end
