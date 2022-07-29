# == Schema Information
#
# Table name: draws
#
#  id         :uuid             not null, primary key
#  approver   :uuid
#  index      :integer          default(1), not null
#  name       :string           not null
#  notes      :text
#  reference  :string
#  state      :string           default("pending"), not null
#  total      :decimal(, )
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :uuid             not null
#
# Indexes
#
#  index_draws_on_project_id_and_index  (project_id,index) UNIQUE
#
class Draw < ApplicationRecord
  include Draws::StateMachine

  ### Params
  ALLOWED_PARAMS = [:index, :name, :notes, :reference, :total]

  ### Associations
  belongs_to :project
  has_many :draw_costs, dependent: :destroy

  ### Validations
  validates :name, presence: true, uniqueness: {scope: :project_id}
  validates :index, presence: true, numericality: { greater_than_or_equal_to: 1}

  def next_index
    return 1 unless project.present?

   (project.draws.pluck(:index).sort.last || 0) + 1
  end

  def budget_variance
    # TODO from approved draw costs
    0.0
  end

  def over_budget?
    budget_variance > 0
  end

  def approve(user)
    self.approver = user
    self.approved_at = Time.current
    save
  end

end
