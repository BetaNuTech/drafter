# == Schema Information
#
# Table name: draw_cost_submissions
#
#  id                       :uuid             not null, primary key
#  amount                   :decimal(, )      default(0.0), not null
#  approval_due_date        :date
#  approved_at              :date
#  audit                    :boolean          default(FALSE), not null
#  manual_approval_required :boolean          default(FALSE), not null
#  multi_invoice            :boolean          default(FALSE), not null
#  ocr_approval             :boolean
#  state                    :string           default("pending"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  approver_id              :uuid
#  draw_cost_request_id     :uuid
#
# Indexes
#
#  index_draw_cost_submissions_on_approver_id           (approver_id)
#  index_draw_cost_submissions_on_draw_cost_request_id  (draw_cost_request_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_cost_request_id => draw_cost_requests.id)
#
class DrawCostSubmission < ApplicationRecord
  include DrawCostSubmissions::StateMachine

  ALLOWED_PARAMS = [:amount]

  ### Associations
  belongs_to :draw_cost_request
  has_one :draw_cost, through: :draw_cost_request, autosave: false
  has_one :draw, through: :draw_cost, autosave: false
  has_one :project, through: :draw, autosave: false
  belongs_to :approver, class_name: 'User', optional: true
  has_one :user, through: :draw_cost_request
  has_one_attached :document

  ### Validations
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0.0 }
  validates :state, presence: true

  def valid_pending_submission?
    state == 'pending' && amount > 0.0
  end

  def approve_submission(user)
    self.approver = user
    self.approved_at = Time.current
    save
  end

  def reject_submission
    self.approver = nil
    self.approved_at = nil
    save
  end
end
