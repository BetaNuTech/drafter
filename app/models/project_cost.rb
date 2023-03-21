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
  ### Concerns
  include ProjectCosts::StateMachine

  class TotalValidator < ActiveModel::Validator
    include ActionView::Helpers::NumberHelper

    def validate(record)
      minimum_total = record.draw_expensed_total - record.change_order_total
      record.errors.add(:total, "must be at least #{number_to_currency(minimum_total)} to balance current expenses") unless record.total >= minimum_total
    end
  end

  ALLOWED_PARAMS = [:id, :approval_lead_time, :cost_type, :name, :total]
  CONTINGENCY_COST_MATCH = /Contingency/
  enum :cost_type, [:land, :hard, :soft, :finance]
  
  ### Associations
  belongs_to :project
  has_many :draw_costs
  has_many :invoices, through: :draw_costs
  has_many :change_orders, dependent: :destroy

  ### Validations
  validates_with TotalValidator, on: :update
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

  def draw_expensed_total
    change_order_funding_total + draw_cost_total
  end

  def budget_balance_without_change_orders
    total - draw_expensed_total
  end

  def budget_balance
    total + change_order_total - draw_expensed_total
  end

  def balance_available_for_draw(draw)
    draw_cost = draw.draw_costs.visible.where(project_cost: self).first
    return budget_balance unless draw_cost.present?

    budget_balance + draw_cost.total - draw_cost.change_order_total
  end

  def invoice_total
    Invoice.includes(draw_cost: :draw).
      totalable.
      where(draws: { state: Draw::VISIBLE_STATES},
            draw_costs: { state: DrawCost::VISIBLE_STATES,
                          project_cost_id: self.id }).
      sum(:amount)
  end

  def draw_cost_total
    DrawCost.includes(:draw).
      where(draws: { state: Draw::VISIBLE_STATES},
            draw_costs: { state: DrawCost::VISIBLE_STATES,
                          project_cost_id: self.id }).
      sum(:total)
  end

  def visible_change_orders
    ChangeOrder.includes(draw_cost: :draw).
      visible.
      where(draws: { state: Draw::VISIBLE_STATES},
            draw_costs: { state: DrawCost::VISIBLE_STATES,
                          project_cost_id: self.id })
  end

  def change_order_total
    visible_change_orders.sum(:amount)
  end

  def visible_change_orders_funded
    ChangeOrder.visible.includes(draw_cost: :draw).
      where(draws: { state: Draw::VISIBLE_STATES},
            draw_costs: { state: DrawCost::VISIBLE_STATES },
            change_orders: { funding_source_id: self.id })
  end

  def change_order_funding_total
    visible_change_orders_funded.sum(:amount)
  end

  def missing_total?
    0.0 >= (total || 0.0)
  end

  def over_budget?
    0.0 > budget_balance
  end

  def contingency?
    name.match?(CONTINGENCY_COST_MATCH)
  end

end
