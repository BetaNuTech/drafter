# == Schema Information
#
# Table name: draws
#
#  id              :uuid             not null, primary key
#  amount          :decimal(, )      default(0.0), not null
#  approved_at     :datetime
#  index           :integer          default(1), not null
#  notes           :text
#  reference       :string
#  state           :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  approver_id     :uuid
#  organization_id :uuid             not null
#  project_id      :uuid             not null
#  user_id         :uuid             not null
#
# Indexes
#
#  draws_assoc_idx                 (project_id,user_id,organization_id,approver_id,state)
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
  include Draws::StateMachine
  include Draws::DrawDocuments

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

  ### Validations
  validates_with IndexValidator
  validates :index, presence: true, numericality: { greater_than_or_equal_to: 1}
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0.0}
  validates :state, presence: true

  ### Callbacks
  after_initialize :assign_index

  def name
    "Draw ##{index}"
  end

  def next_index
    return 1 unless project.present?

   (project.draws.visible.pluck(:index).sort.last || 0) + 1
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
    change_orders.none?
  end

  def mark_invoices_for_manual_approval
    return false unless ( pending? || submitted? )

    invoices.mark_random_selection_for_manual_approval
  end
end
