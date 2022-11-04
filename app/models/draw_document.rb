# == Schema Information
#
# Table name: draw_documents
#
#  id                :uuid             not null, primary key
#  approval_due_date :date
#  approved_at       :datetime
#  documenttype      :integer          default("other"), not null
#  notes             :text
#  state             :string           default("pending")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  approver_id       :uuid
#  draw_id           :uuid             not null
#  user_id           :uuid
#
# Indexes
#
#  draw_documents_assoc_idx              (draw_id,user_id)
#  index_draw_documents_on_approver_id   (approver_id)
#  index_draw_documents_on_documenttype  (documenttype)
#  index_draw_documents_on_draw_id       (draw_id)
#  index_draw_documents_on_state         (state)
#  index_draw_documents_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_id => draws.id)
#  fk_rails_...  (user_id => users.id)
#
class DrawDocument < ApplicationRecord
  ALLOWED_PARAMS = %i{notes documenttype document}.freeze
  OTHER_DESCRIPTION = 'Other'
  BUDGET_DESCRIPTION = 'Budget'
  APPLICATION_DESCRIPTION = 'Application and Certificate of Payment'
  WAIVER_DESCRIPTION = 'Waiver of Lien'
  REQUIRED_DOCUMENTTYPES = %i{budget application waiver}.freeze

  ### Concerns
  include DrawDocuments::StateMachine

  ### Associations
  belongs_to :approver, class_name: 'User', optional: true
  belongs_to :draw
  has_one :project, through: :draw
  belongs_to :user, optional: true
  has_one :organization, through: :user
  has_one_attached :document

  ### Enums
  enum :documenttype, [:other, :budget, :application, :waiver]

  ### Validations
  validates :documenttype, presence: true, uniqueness: { scope: :draw_id }

  ### Scopes
  scope :budget, -> { where(documenttype: :budget) }
  scope :application, -> { where(documenttype: :application) }
  scope :waiver, -> { where(documenttype: :waiver) }

  ### Instance Methods
  
  def description
    {
      other: OTHER_DESCRIPTION,
      budget: BUDGET_DESCRIPTION,
      application: APPLICATION_DESCRIPTION,
      waiver: WAIVER_DESCRIPTION
    }.fetch(documenttype.to_sym)
  end

  def mark_approval_by(user)
    self.approver = user
    self.approved_at = Time.current
    save
  end

  def unapprove
    self.approver = nil
    self.approved_at = nil
    save
  end
end
