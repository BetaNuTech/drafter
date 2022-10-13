# == Schema Information
#
# Table name: project_costs
#
#  id                 :uuid             not null, primary key
#  approval_lead_time :integer          default(0), not null
#  cost_type          :integer          not null
#  name               :string           not null
#  state              :string           default("pending"), not null
#  total              :decimal(, )      default(0.0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  project_id         :uuid             not null
#
# Indexes
#
#  draw_costs_project_idx             (project_id,state)
#  index_project_costs_on_project_id  (project_id)
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

end
