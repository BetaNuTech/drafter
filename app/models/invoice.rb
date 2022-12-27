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
class Invoice < ApplicationRecord
  # invoice.ocr_data
  # { meta: { attempts: 0, requests: [{timestamp: timestamp, request_token: 'XXX'}], documentid: document.id, jobid: 'TextractJobId', key: 'S3ObjectKey', filename: 'filename.pdf', last_attempt: timestamp, service: 'Textract'}, analysis: {} }
  
  ALLOWED_PARAMS = %i{amount description document}
  PROCESSING_QUEUE = :invoice_processing
  
  ### Concerns
  include Invoices::StateMachine

  ### Associations
  belongs_to :draw_cost
  belongs_to :approver, optional: true, class_name: 'User'
  belongs_to :user
  has_one :project, through: :draw_cost
  has_one_attached :document
  has_one_attached :annotated_preview

  ### Validations
  validates :amount, presence: true, numericality: { greater_than: 0.0}
  validates :state, presence: true

  delegate :organization, to: :draw_cost

  def self.analyze_submitted
    self.submitted.each do |invoice|
      invoice.delay(queue: PROCESSING_QUEUE).start_analysis
    end
  end

  def init_ocr_data
    self.ocr_data ||= {}
    self.ocr_data['analysis'] ||= {}
    self.ocr_data['meta'] ||= {}
    self.ocr_data['meta']['attempts'] ||= 0
    self.ocr_data['meta']['requests'] ||= []

    if document.attached?
      self.ocr_data['meta']['documentid'] = document.id
      self.ocr_data['meta']['key'] = document.attachment.blob.key
      self.ocr_data['meta']['filename'] = document.attachment.blob.filename.to_s
    end
  end

  def start_analysis(force: false)
    InvoiceProcessingService.new.
      start_analysis(invoice: self, force: )
  rescue
    true
  end

  def process_analysis
    service = InvoiceProcessingService.new
    analysis_job_data = service.get_analysis(invoice: self)
    service.process_analysis_job_data(invoice: self, analysis_job_data:)
  end

  def generate_annotated_preview
    service = InvoiceProcessingService.new
    service.generate_annotated_preview(invoice: self)
  end

end
