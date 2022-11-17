# == Schema Information
#
# Table name: project_costs
#
#  id                     :uuid             not null, primary key
#  approval_lead_time     :integer          default(0), not null
#  change_request_allowed :boolean          default(TRUE)
#  change_requestable     :boolean          default(TRUE)
#  cost_type              :integer          not null
#  drawable               :boolean          default(TRUE)
#  initial_draw_only      :boolean          default(FALSE)
#  name                   :string           not null
#  state                  :string           default("pending"), not null
#  total                  :decimal(, )      default(0.0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  project_id             :uuid             not null
#
# Indexes
#
#  index_project_costs_on_project_id  (project_id)
#  project_costs_drawable_idx         (drawable,change_requestable,initial_draw_only,change_request_allowed)
#  project_costs_project_idx          (project_id,state)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
class ProjectCost < ApplicationRecord
  include ProjectCosts::StateMachine

  ALLOWED_PARAMS = [:id, :approval_lead_time, :cost_type, :name, :total]
  enum :cost_type, [:land, :hard, :soft, :finance]
  
  ### Associations
  belongs_to :project
  has_many :draw_costs
  has_many :invoices, through: :draw_costs
  has_many :change_orders, dependent: :destroy

  ### Validations
  validates :approval_lead_time, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :cost_type, presence: true
  validates :name, presence: true
  validates :state, presence: true
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0.0 }

  ### Scopes
  scope :drawable, -> { where(drawable: true) }
  scope :drawable_and_non_initial, -> { where(drawable: true, initial_draw_only: false) }
  scope :change_requestable, -> { where(change_requestable: true) }
  scope :change_request_allowed, -> { where(change_request_allowed: true) }
  scope :initial_draw_only, -> { where(initial_draw_only: true) }

  def cost_type_css_class
    {
      land: 'secondary',
      hard: 'primary',
      soft: 'info',
      finance: 'success'
    }.fetch(cost_type.to_sym)
  end

  def budget_balance
    total + change_order_total - change_order_funding_total - draw_cost_total
  end

  def budget_balance_without_change_orders
    total - change_order_funding_total - draw_cost_total
  end

  def invoice_total
    Invoice.includes(draw_cost: :draw).
      where(draws: { state: Draw::VISIBLE_STATES},
            draw_costs: { state: DrawCost::VISIBLE_STATES,
                          project_cost_id: self.id }).
      totalable.
      sum(:amount)
  end

  def draw_cost_total
    DrawCost.includes(:draw).
      where(draws: { state: Draw::VISIBLE_STATES},
            draw_costs: { state: DrawCost::VISIBLE_STATES,
                          project_cost_id: self.id }).
      sum(:total)
  end

  def change_order_total
    ChangeOrder.includes(draw_cost: :draw).
      where(draws: { state: Draw::VISIBLE_STATES},
            draw_costs: { state: DrawCost::VISIBLE_STATES,
                          project_cost_id: self.id }).
      sum(:amount)
  end

  def change_order_funding_total
    ChangeOrder.includes(draw_cost: :draw).
      where(draws: { state: Draw::VISIBLE_STATES},
            draw_costs: { state: DrawCost::VISIBLE_STATES,
                          project_cost_id: self.id},
            change_orders: { funding_source_id: self.id }).
      sum(:amount)
  end

  def missing_total?
    0.0 >= (total || 0.0)
  end

  def over_budget?
    0.0 > budget_balance
  end

end
