# == Schema Information
#
# Table name: draw_documents
#
#  id           :uuid             not null, primary key
#  approved_at  :datetime
#  documenttype :integer          default("other"), not null
#  notes        :text
#  state        :string           default("pending")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  approver_id  :uuid
#  draw_id      :uuid             not null
#  user_id      :uuid
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
  class DocumenttypeValidator < ActiveModel::Validator
    def validate(record)
      return true if record.documenttype == 'other'

      if record.draw.draw_documents.
          visible.
          where(documenttype: record.documenttype).
          where.not(id: record.id).any?
        record.errors.add(:documenttype, 'is not unique')
      end
    end
  end

  ALLOWED_PARAMS = %i{notes documenttype document}.freeze
  OTHER_DESCRIPTION = 'Other'
  BUDGET_DESCRIPTION = 'Budget'
  APPLICATION_DESCRIPTION = 'Application and Certificate of Payment'
  WAIVER_DESCRIPTION = 'Waiver of Lien'
  REQUIRED_DOCUMENTTYPES = %i{budget application waiver}.freeze
  APPROVAL_LEAD_TIME = 7 # days

  ### Concerns
  include DrawDocuments::StateMachine

  ### Associations
  belongs_to :approver, class_name: 'User', optional: true
  belongs_to :draw
  has_one :project, through: :draw
  belongs_to :user, optional: true
  has_one :organization, through: :user
  has_one_attached :document
  has_many :project_tasks, as: :origin, dependent: :destroy

  ### Enums
  enum :documenttype, [:other, :budget, :application, :waiver]

  ### Validations
  validates :documenttype, presence: true
  validates_with DocumenttypeValidator, fields: %i{documenttype}

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

  def create_task(action:, assignee: nil)
    ProjectTaskServices::Generator.call(origin: self, assignee: , action: )
  end

  def approval_lead_time
    APPROVAL_LEAD_TIME
  end
end
