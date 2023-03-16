# == Schema Information
#
# Table name: invoices
#
#  id                       :uuid             not null, primary key
#  amount                   :decimal(, )      default(0.0), not null
#  approved_at              :datetime
#  approved_by_desc         :string
#  audit                    :boolean          default(FALSE), not null
#  automatically_approved   :boolean          default(FALSE)
#  description              :string
#  manual_approval_required :boolean          default(TRUE), not null
#  multi_invoice            :boolean
#  ocr_amount               :decimal(, )
#  ocr_data                 :json
#  ocr_processed            :datetime
#  state                    :string           default("pending"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  approver_id              :uuid
#  draw_cost_id             :uuid
#  user_id                  :uuid
#
# Indexes
#
#  index_invoices_on_approver_id   (approver_id)
#  index_invoices_on_draw_cost_id  (draw_cost_id)
#  index_invoices_on_user_id       (user_id)
#  invoices_assoc_idx              (draw_cost_id,user_id,approver_id)
#  invoices_state_idx              (state,audit,manual_approval_required,ocr_processed)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_cost_id => draw_costs.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Invoice, type: :model do
  include_context 'sample_draws'

  let(:file_upload) { fixture_file_upload('sample_document_1.pdf') }

  describe 'Initialization' do
    it 'initializes an invoice' do
      invoice = create(:invoice, draw_cost: draw_cost)
      assert(invoice.is_a?(Invoice))
    end
  end

  describe 'helper methods' do
    let(:invoice) { create(:invoice, draw_cost: draw_cost) }
    describe 'initializing ocr_data' do
      it 'without an attached document' do
        expect(invoice.ocr_data).to be_nil
        invoice.init_ocr_data
        invoice.save

        expect(invoice.ocr_data).to be_a(Hash)
        assert(invoice.ocr_data['meta'].present?)
        expect(invoice.ocr_data['meta']['attempts']).to eq(0)
        assert(invoice.ocr_data.dig('meta','documentid').nil?)
        assert(invoice.ocr_data.dig('meta','key').nil?)
        assert(invoice.ocr_data.dig('meta','filename').nil?)
      end
      it 'with an attached document' do
        expect(invoice.ocr_data).to be_nil
        invoice.document = file_upload
        invoice.save!

        invoice.init_ocr_data
        invoice.save!

        expect(invoice.ocr_data).to be_a(Hash)
        assert(invoice.ocr_data['meta'].present?)
        expect(invoice.ocr_data['meta']['attempts']).to eq(0)
        expect(invoice.ocr_data.dig('meta','documentid')).to eq(invoice.document.id)
        expect(invoice.ocr_data.dig('meta','key')).to eq(invoice.document.attachment.blob.key)
        expect(invoice.ocr_data.dig('meta','filename')).to eq(invoice.document.attachment.blob.filename.to_s)
      end
    end
  end

  describe 'class methods' do
      let(:invoice0) { create(:invoice, draw_cost: draw_cost2, state: :pending, amount: 1000.0, manual_approval_required: false, description: 'invoice0') }
      let(:invoice1) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 1000.0, manual_approval_required: false, description: 'invoice1') }
      let(:invoice2) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 2000.0, manual_approval_required: false, description: 'invoice2') }
      let(:invoice3) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 3000.0, manual_approval_required: false, description: 'invoice3') }
      let(:invoice4) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 4000.0, manual_approval_required: false, description: 'invoice4') }
      let(:invoice5) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 5000.0, manual_approval_required: false, description: 'invoice5') }
      let(:invoice6) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 6000.0, manual_approval_required: false, description: 'invoice6') }
      let(:invoice7) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 7000.0, manual_approval_required: false, description: 'invoice7') }
      let(:invoice8) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 8000.0, manual_approval_required: false, description: 'invoice8') }
      let(:invoice9) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 9000.0, manual_approval_required: false, description: 'invoice9') }
      let(:invoice10) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 10000.0, manual_approval_required: false, audit: false, description: 'invoice10') }
      let(:invoice11) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 10000.0, manual_approval_required: false, audit: true, description: 'invoice11') }
      let(:invoice12) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 10000.0, manual_approval_required: true, description: 'invoice12') }

      let(:invoices) {
        [ invoice0, invoice1, invoice2, invoice3, invoice4, invoice5, invoice6, invoice7,
          invoice8, invoice9, invoice10, invoice11, invoice12 ]
      }
    describe 'mark random selection for manual approval' do

      it 'marks a random selection of high value and other invoices that passed other QC controls' do
        draw_cost
        Invoice.destroy_all
        invoices
        processed = Invoice.mark_random_selection_for_manual_approval
        expect(processed.size).to eq(2)
        expect(Invoice.where(manual_approval_required: true).size).to eq(3)
      end
    end

    #describe 'mark and trigger approval for invoices not requiring manual approval' do
      #before do
        #draw_documents
        #draw_cost
        #draw_cost2
        #Invoice.destroy_all
        #invoices
        #draw_cost.total = draw_cost.invoice_total
        #draw_cost.save!
        #pc1 = draw_cost.project_cost
        #pc1 = draw_cost.project_cost
        #pc1.total = draw_cost.total
        #pc1.save!
        #pc2 = draw_cost2.project_cost
        #pc2.total = draw_cost2.total
        #pc2.save!
        #draw_cost2.total = draw_cost2.invoice_total
        #draw_cost2.save!
        #draw.reload
      #end
      it 'triggers approval and marks the records as automatically approved' do
        pending 'Test auto-approve process'
        assert(false)
        #draw.trigger_event(event_name: :submit)
        #draw_cost.invoices.reload
        #expect(draw_cost.invoices.approved.size).to eq(9)
      end
    #end

  end

  describe 'state machine' do
    let(:invoice) { create(:invoice, draw_cost: draw_cost, state: :processing, amount: 1000.0, manual_approval_required: false) }

    describe 'processing' do
      describe 'task creation' do
        it 'creates a task if the Draw has already run auto invoice approvals' do
          refute(invoice.manual_approval_required)
          invoice.draw.invoice_auto_approvals_completed = true
          invoice.draw.save
          expect{
            invoice.trigger_event(event_name: :complete_processing)  
          }.to change{ProjectTask.count}.by(1)
          invoice.project_tasks.reload
          expect(invoice.project_tasks.count).to eq(1)
          assert(invoice.manual_approval_required)
        end
        it 'does not create a task if the Draw not already run auto invoice approvals' do
          expect{
            invoice.trigger_event(event_name: :fail_processing)  
          }.to_not change{ProjectTask.count}
          invoice.project_tasks.reload
          expect(invoice.project_tasks.count).to eq(0)
        end
      end
    end

    describe 'resetting approval' do
      it 'sets flags to require manual approval' do
        invoice.update(state: :approved, automatically_approved: true, manual_approval_required: false)
        invoice.trigger_event(event_name: :reset_approval)
        invoice.reload
        assert(invoice.submitted?)
        assert(invoice.manual_approval_required?)
        refute(invoice.automatically_approved?)
      end
    end

    describe 'remove' do
      let(:pending_invoice_tasks) {
        Array.new(1) {
          ProjectTaskServices::Generator.call(origin: invoice, action: :approve)
        }
      }
      it 'archives pending tasks' do
        invoice.state = 'pending'
        invoice.save!
        pending_invoice_tasks
        invoice.project_tasks.reload
        expect(invoice.project_tasks.archived.count).to eq(0)
        expect(invoice.project_tasks.pending.count).to eq(1)
        task_count = invoice.project_tasks.count
        assert(invoice.allow_remove?)
        invoice.trigger_event(event_name: :remove)
        invoice.project_tasks.reload
        expect(invoice.project_tasks.count).to eq(task_count)
        expect(invoice.project_tasks.archived.count).to eq(1)
        expect(invoice.project_tasks.pending.count).to eq(0)
      end

    end # remove

    describe 'approve' do
      describe 'the last draw cost invoice' do
        let(:invoice1) { draw_cost_invoices.first }
        let(:invoice2) { draw_cost_invoices.last }

        before do
          draw.update(state: :submitted)
          draw_cost.update(state: :rejected)
          invoice1.update(state: :approved)
          invoice2.update(state: :submitted)
        end

        describe 'when the draw cost is submitted' do
          it 'approves the draw cost' do
            invoice2.trigger_event(event_name: :approve)
            invoice2.reload
            expect(invoice2.state).to eq('approved')
            draw_cost.reload
            expect(draw_cost.state).to eq('approved')
          end
        end
        describe 'when the draw cost is rejected' do
          it 'approves the draw cost' do
            invoice2.trigger_event(event_name: :approve)
            invoice2.reload
            expect(invoice2.state).to eq('approved')
            draw_cost.reload
            expect(draw_cost.state).to eq('approved')
          end
        end
        describe 'when the draw cost uses contingency funds' do
          let(:change_order_amount) { 1000.0 }
          let(:contingency_project_cost) {
            cost = create(:project_cost, project: sample_project, name: 'Sample Contingency', total: 1000000.0)
            sample_project.project_costs.reload
            cost
          }
          let(:change_order) {
            project_cost = draw_cost.project_cost
            contingency_project_cost
            create(:change_order,
                   amount: change_order_amount,
                   draw_cost: draw_cost,
                   project_cost: draw_cost.project_cost,
                   funding_source: contingency_project_cost)
          }
          
          it 'approves the draw cost' do
            draw_cost.total = draw_cost.total + change_order_amount
            draw_cost.save!
            expect(ChangeOrder.count).to eq(0)
            change_order
            expect(ChangeOrder.count).to eq(1)
            change_order.trigger_event(event_name: :approve)
            draw_cost.change_orders.reload
            assert(draw_cost.uses_contingency?)
            invoice1; invoice2
            invoice2.trigger_event(event_name: :approve)
            invoice2.reload
            expect(invoice2.state).to eq('approved')
            draw_cost.reload
            expect(draw_cost.state).to eq('approved')
          end

        end
      end # approve

      describe 'reject' do
        let(:invoice1) { draw_cost_invoices.first }
        let(:invoice2) { draw_cost_invoices.last }

        before do
          draw.update(state: :submitted)
          draw_cost.update(state: :submitted)
          invoice1.update(state: :processed)
          invoice2.update(state: :processed)
        end

        describe 'when the draw cost is approved' do
          it 'rejects the draw cost' do
            assert(draw_cost.submitted?)

            invoice1.trigger_event(event_name: :approve)
            invoice2.trigger_event(event_name: :approve)
            invoice2.trigger_event(event_name: :reject)
            draw_cost.reload
            assert(draw_cost.rejected?)
          end
        end
      end
    end 


  end


end
