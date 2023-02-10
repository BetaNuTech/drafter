# == Schema Information
#
# Table name: invoices
#
#  id                       :uuid             not null, primary key
#  amount                   :decimal(, )      default(0.0), not null
#  approved_at              :datetime
#  approved_by_desc         :string
#  audit                    :boolean          default(FALSE), not null
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
    describe 'mark random selection for manual approval' do
      let(:invoice1) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 1000.0, manual_approval_required: false) }
      let(:invoice2) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 2000.0, manual_approval_required: false) }
      let(:invoice3) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 3000.0, manual_approval_required: false) }
      let(:invoice4) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 4000.0, manual_approval_required: false) }
      let(:invoice5) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 5000.0, manual_approval_required: false) }
      let(:invoice6) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 6000.0, manual_approval_required: false) }
      let(:invoice7) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 7000.0, manual_approval_required: false) }
      let(:invoice8) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 8000.0, manual_approval_required: false) }
      let(:invoice9) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 9000.0, manual_approval_required: false) }
      let(:invoice10) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 10000.0, manual_approval_required: false) }

      let(:invoice11) { create(:invoice, draw_cost: draw_cost, state: :pending, amount: 1000.0, manual_approval_required: false) }
      let(:invoice12) { create(:invoice, draw_cost: draw_cost, state: :processed, amount: 1000.0, manual_approval_required: true) }

      let(:invoices) {
        [ invoice1, invoice2, invoice3, invoice4, invoice5, invoice6, invoice7,
          invoice8, invoice9, invoice10, invoice11, invoice12 ]
      }

      it 'marks a random selection of high value and other invoices that passed other QC controls' do
        invoices
        assert(Invoice.mark_random_selection_for_manual_approval)
        expect(Invoice.processed.where(manual_approval_required: false).count).to eq(8)
      end

      it 'returns false if there are no passing processed invoices' do
        invoice11; invoice12
        refute(Invoice.mark_random_selection_for_manual_approval)

        invoice10
        assert(Invoice.mark_random_selection_for_manual_approval)
      end
    end

  end

  describe 'state machine' do
    let(:invoice) { create(:invoice, draw_cost: draw_cost, state: :processing, amount: 1000.0, manual_approval_required: false) }

    describe 'processing' do
      it 'creates a project task after failed processing' do
        expect{
          invoice.trigger_event(event_name: :fail_processing)  
        }.to change{ProjectTask.count}.by(1)
        invoice.project_tasks.reload
        expect(invoice.project_tasks.count).to eq(1)
      end
      it 'creates a project task after successful processing' do
        expect{
          invoice.trigger_event(event_name: :complete_processing)  
        }.to change{ProjectTask.count}.by(1)
        invoice.project_tasks.reload
        expect(invoice.project_tasks.count).to eq(1)
      end
    end

    describe 'remove' do
      let(:completed_invoice_tasks) {
        Array.new(3) {
          task = ProjectTaskServices::Generator.call(origin: invoice, action: :approve)
          task.state = 'approved'; task.save!
          task
        }
      }
      let(:pending_invoice_tasks) {
        Array.new(2) {
          task = ProjectTaskServices::Generator.call(origin: invoice, action: :approve)
          task.state = 'needs_review'; task.save!
          task
        }
      }
      it 'archives pending tasks' do
        invoice.state = 'pending'
        invoice.save!
        completed_invoice_tasks
        pending_invoice_tasks
        invoice.project_tasks.reload
        expect(invoice.project_tasks.approved.count).to eq(3)
        expect(invoice.project_tasks.pending.count).to eq(2)
        task_count = invoice.project_tasks.count
        assert(invoice.allow_remove?)
        invoice.trigger_event(event_name: :remove)
        invoice.project_tasks.reload
        expect(invoice.project_tasks.count).to eq(task_count)
        expect(invoice.project_tasks.approved.count).to eq(3)
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
          invoice1.update(state: 'approved')
          invoice2.update(state: 'submitted')
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
            sample_project.project_costs.select{|pc| pc.contingency? }.first
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
      end
    end
  end


end
