# == Schema Information
#
# Table name: change_orders
#
#  id                         :uuid             not null, primary key
#  amount                     :decimal(, )
#  description                :text
#  integration_attempt_at     :datetime
#  integration_attempt_number :integer
#  state                      :string           default("pending")
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  draw_cost_id               :uuid             not null
#  external_task_id           :string
#  funding_source_id          :uuid             not null
#  project_cost_id            :uuid             not null
#
# Indexes
#
#  index_change_orders_on_draw_cost_id_and_state  (draw_cost_id,state)
#  index_change_orders_on_funding_source_id       (funding_source_id)
#  index_change_orders_on_project_cost_id         (project_cost_id)
#
# Foreign Keys
#
#  fk_rails_...  (draw_cost_id => draw_costs.id)
#  fk_rails_...  (funding_source_id => project_costs.id)
#  fk_rails_...  (project_cost_id => project_costs.id)
#
class ChangeOrder < ApplicationRecord
  include ChangeOrders::StateMachine

  class FundingAmountValidator < ActiveModel::Validator
    include ActionView::Helpers::NumberHelper

    def validate(record)
      effective_balance = record.new_record? ? record.funding_source.budget_balance :
        (record.funding_source.budget_balance + record.amount)
      if effective_balance < record.amount
        record.errors.add(:amount, 'exceeds the funding source\'s budget')
      end

      variance = record.draw_cost.change_orders.where.not(id: record.id).sum(:amount) + record.amount - record.draw_cost.total
      if variance.positive?
        record.errors.add(:amount, "will over-fund the Draw Cost by #{number_to_currency(variance)}")
      end
    end
  end

  class FundingSourceValidator < ActiveModel::Validator
    def validate(record)
      if record.funding_source_id == record.project_cost_id
        record.errors.add(:funding_source_id, 'can\'t be the same as the Project Cost')
      end
      if record.draw_cost.change_orders.
            visible.
            where(funding_source_id: record.funding_source_id).
            where.not(id: record.id).
          any?
        record.errors.add(:funding_source_id, 'is being used by another Change Order for this Draw Cost')
      end
    end
  end

  ALLOWED_PARAMS = %i{amount description funding_source_id}.freeze

  ### Associations
  belongs_to :project_cost
  belongs_to :draw_cost
  belongs_to :funding_source, class_name: 'ProjectCost'
  has_one :project, through: :draw_cost
  has_one :draw, through: :draw_cost
  has_many :project_tasks, as: :origin, dependent: :destroy

  ### Validations
  validates_with FundingAmountValidator
  validates_with FundingSourceValidator
  validates :amount, presence: true, numericality: { greater_than: 0.0 }
  #validates :funding_source_id, exclusion: { in: ->(change_order) { [change_order.project_cost_id] } },
                                #uniqueness: { scope: [:draw_cost_id],
                                              #message: 'is being used by another Change Order for this Draw Cost' }

  def self.create_approval_tasks
    self.all.pending.each do |change_order|
      change_order.create_task(action: :approve)
    end
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
    contingency?
  end

  def contingency?
    funding_source.contingency?
  end
  
  def possible_project_costs_for_funding
    return ProjectCost.none unless draw_cost_id.present?

    draw_cost_funding_source_ids = [ draw_cost.project_cost_id ] +
                                     draw_cost.change_order_funding_sources.pluck(:id)
    project.project_costs.
      change_requestable.
      where.not(id: draw_cost_funding_source_ids).
      order(name: :asc).
      select{ |cost| cost.budget_balance > 0.0 }
  end

end
