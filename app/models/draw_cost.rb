# == Schema Information
#
# Table name: draw_costs
#
#  id                 :uuid             not null, primary key
#  approval_lead_time :integer          default(0), not null
#  cost_type          :integer          not null
#  name               :string           not null
#  state              :string           default("pending"), not null
#  total              :decimal(, )      default(0.0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  draw_id            :uuid             not null
#
# Indexes
#
#  draw_costs_idx               (draw_id,state)
#  index_draw_costs_on_draw_id  (draw_id)
#
# Foreign Keys
#
#  fk_rails_...  (draw_id => draws.id)
#
class DrawCost < ApplicationRecord
  include DrawCosts::StateMachine

  ALLOWED_PARAMS = [:id, :approval_lead_time, :cost_type, :name, :total]
  enum :cost_type, [:land, :hard, :soft, :finance]
  
  ### Associations
  belongs_to :draw
  has_one :project, through: :draw
  has_many :draw_cost_requests

  ### Validations
  validates :approval_lead_time, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :cost_type, presence: true
  validates :name, presence: true
  validates :state, presence: true
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0.0 }

  def cost_type_css_class
    {
      land: 'secondary',
      hard: 'primary',
      soft: 'info',
      finance: 'success'
    }.fetch(cost_type.to_sym)
  end

  def clean?
    # TODO
    true
  end

end
