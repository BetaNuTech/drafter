# == Schema Information
#
# Table name: draws
#
#  id                               :uuid             not null, primary key
#  amount                           :decimal(, )      default(0.0), not null
#  approved_at                      :datetime
#  index                            :integer          default(0), not null
#  invoice_auto_approvals_completed :boolean          default(FALSE)
#  notes                            :text
#  reference                        :string
#  state                            :string           default("pending"), not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  approver_id                      :uuid
#  organization_id                  :uuid             not null
#  project_id                       :uuid             not null
#  user_id                          :uuid             not null
#
# Indexes
#
#  draws_assoc_idx                 (project_id,user_id,organization_id,approver_id,state)
#  draws_auto_approval_idx         (state,invoice_auto_approvals_completed)
#  index_draws_on_approver_id      (approver_id)
#  index_draws_on_organization_id  (organization_id)
#  index_draws_on_project_id       (project_id)
#  index_draws_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class Draw < ApplicationRecord
  include Draws::DrawDocuments
  include Draws::Reporting
  include Draws::StateMachine

  class IndexValidator < ActiveModel::Validator
    def validate(record)
      return false unless record.project.present?

      skope = record.project.draws.where(state: Draw::VISIBLE_STATES, index: record.index)
      conflict = record.new_record? ? skope.any? : skope.where.not(id: record.id).any?
      record.errors.add(:index, 'There is already a Draw with this number') if conflict
      true
    end
  end

  ### Params
  ALLOWED_PARAMS = [:amount, :notes ]

  ### Scopes
  scope :for_organization, -> (organization) { where(organization: organization) }

  ### Associations
  belongs_to :project
  belongs_to :organization
  belongs_to :user
  belongs_to :approver, class_name: 'User', optional: true
  has_many :draw_costs, dependent: :destroy
  has_many :change_orders, through: :draw_costs
  has_many :invoices, through: :draw_costs
  has_many :project_tasks, as: :origin, dependent: :destroy
  has_one_attached :document_packet
  has_one_attached :draw_summary_sheet

  ### Validations
  validates_with IndexValidator
  validates :index, presence: true, numericality: { greater_than_or_equal_to: 0}
  validates :amount, presence: true
  validates :state, presence: true

  ### Callbacks
  after_initialize :assign_index

  def self.invoice_auto_approval
    Draw.submitted.each do |draw|
      DrawService.new(user: nil, draw:).auto_approve_invoices
    end
  end

  def self.create_approval_tasks
    tasks = []
    where(state: :submitted).each do |draw|
      next if draw.project_tasks.active.any?
      next if draw.invoices.where(state: %i{approved rejected}).none? ||
                draw.invoices.pending.any? ||
                draw.invoices.approval_pending.any?
      next if ( draw.change_orders.visible.any? &&
                (draw.change_orders.where(state: %i{approved rejected}).none? ||
                  draw.change_orders.pending.any? ))

      tasks << draw.create_task(action: :approve)
    end

    tasks
  end

  def name
    "Draw ##{index}"
  end

  def next_index
    return 0 unless project.present?

    # Start at 0 OR +1 last index
   (project.draws.visible.pluck(:index).sort.last || -1) + 1
  end

  def draw_cost_total
    draw_costs.visible.sum(:total)
  end

  def draw_cost_invoices_total
    draw_costs.reload
    draw_costs.visible.map(&:invoice_total).sum
  end

  def all_draw_costs_approved?
    match_states = %i{pending submitted rejected approved}
    draw_cost_states = draw_costs.where(state: match_states).
                    pluck(:state).map(&:to_sym).uniq
    draw_cost_states.size == 1 && draw_cost_states.first == :approved
  end

  def unapproved_draw_costs
    match_states = %i{pending submitted rejected}
    draw_costs.where(state: match_states)
  end

  def approve(user)
    self.approver = user
    self.approved_at = Time.current
    save
  end

  def assign_reference?
    approved? 
  end

  def assign_index
    if new_record?
      _next_index = next_index
      self.index = _next_index unless self.index >= _next_index
    end
  end

  def clean?
    !change_orders.any?(&:contingency?)
  end

  def create_task(action:, assignee: nil)
    ProjectTaskServices::Generator.call(origin: self, assignee:, action: ).
      trigger_event(event_name: :submit_for_review)
  end

  def send_state_notification(new_state=nil)
    mailer = NotificationMailer.with(draw: self, state: ( new_state || state )).
      draw_status_notification

    if Rails.env.test?
      mailer.deliver
    else
      mailer.deliver_later
    end
  end
end
