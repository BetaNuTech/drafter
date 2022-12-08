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


end
