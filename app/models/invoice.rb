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
class Invoice < ApplicationRecord
  # invoice.ocr_data
  # { meta: { attempts: 0, requests: [{timestamp: timestamp, request_token: 'XXX'}], documentid: document.id, jobid: 'TextractJobId', key: 'S3ObjectKey', filename: 'filename.pdf', last_attempt: timestamp, service: 'Textract'}, analysis: {} }
  
  ALLOWED_PARAMS = %i{amount description document}
  PROCESSING_QUEUE = :invoice_processing
  RANDOM_SELECTION_RATIO = 0.1
  
  ### Concerns
  include Invoices::StateMachine

  ### Associations
  belongs_to :draw_cost
  belongs_to :approver, optional: true, class_name: 'User'
  belongs_to :user
  has_one :draw, through: :draw_cost
  has_one :project, through: :draw_cost
  has_one_attached :document
  has_one_attached :annotated_preview
  has_many :project_tasks, as: :origin, dependent: :destroy

  ### Validations
  validates :amount, presence: true, numericality: { greater_than: 0.0}
  validates :state, presence: true

  delegate :organization, to: :draw_cost

  def self.analyze_submitted
    self.submitted.each do |invoice|
      invoice.delay(queue: PROCESSING_QUEUE).start_analysis
    end
  end

  def self.mark_random_selection_for_manual_approval
    sample_invoices = self.all.where(manual_approval_required: false)
    return Invoice.none if sample_invoices.none?

    sample_invoice_count = sample_invoices.size
    sample_size = [1, ( sample_invoice_count.to_f * RANDOM_SELECTION_RATIO ).to_i].max
    high_value_invoices = sample_invoices.order(amount: :desc).limit((sample_size))
    high_value_invoice_ids = sample_invoices.where(id: high_value_invoices.pluck(:id)).
                                limit(sample_size).
                                pluck(:id)

    random_sample_invoice_count = sample_invoices.size - high_value_invoice_ids.size
    random_sample_size = [1, ( random_sample_invoice_count.to_f * RANDOM_SELECTION_RATIO ).to_i].max
    random_invoice_ids = sample_invoices.where.not(id: high_value_invoice_ids).
                                order('RANDOM()').
                                limit(random_sample_size).
                                pluck(:id)

    invoices_for_processing_ids = high_value_invoice_ids + random_invoice_ids
    invoices_for_processing = sample_invoices.where(id: invoices_for_processing_ids)
    return Invoice.none if invoices_for_processing.none?

    invoices_for_processing.update(manual_approval_required: true)
    invoices_for_processing
  end

  def self.auto_approve
    self.all.where(manual_approval_required: false).each do |invoice|
      invoice.automatically_approved = true
      invoice.trigger_event(event_name: :approve)
    end
  end

  def self.create_approval_tasks
    self.all.approval_pending.each do |invoice|
      invoice.create_task(action: :approve)
    end
  end

  def self.all_documents_attached?
    !self.all.any?{|invoice| !invoice.document.attached?}
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

  def create_task(action:, assignee: nil)
    task = ProjectTaskServices::Generator.call(origin: self, assignee: , action: )
    if consult?
      task.trigger_event(event_name: :submit_for_consult)
    else
      task.trigger_event(event_name: :submit_for_review)
    end

    task
  end

  def archive_project_tasks
    project_tasks.each{|task| task.trigger_event(event_name: :archive)}
  end

  def consult?
    draw_cost&.consult?
  end

  def descriptive_name
    "%{draw_cost} Invoice for %{amount}" % {draw_cost: draw_cost.name, amount: "$%0.2f" % amount }
  end

  def ocr_matched?
    ocr_processed.present? && ocr_amount.present? && ocr_amount == amount
  end

  def ocr_no_match?
    ocr_processed.present? && ocr_amount.present? && ocr_amount != amount
  end

  def ocr_failed?
    ocr_processed.present? && ocr_amount.nil?
  end

  def has_processing_errors?
    SystemEvent.error.where(event_source: self, description: MAX_ATTEMPT_ERROR).any?
  end

end
