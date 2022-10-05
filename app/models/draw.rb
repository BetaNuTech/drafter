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
#  index_draws_on_project_id            (project_id)
#  index_draws_on_project_id_and_index  (project_id,index) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
class Draw < ApplicationRecord
  include Draws::StateMachine

  ### Params
  ALLOWED_PARAMS = [:index, :name, :notes, :reference, :total]

  ### Associations
  belongs_to :project
  has_many :draw_costs, dependent: :destroy
  has_many :draw_cost_requests, through: :draw_costs
  has_many :draw_cost_submissions, through: :draw_cost_requests

  ### Validations
  validates :name, presence: true, uniqueness: {scope: :project_id}, allow_blank: false
  validates :index, presence: true, numericality: { greater_than_or_equal_to: 1}, uniqueness: {scope: :project_id}

  def next_index
    return 1 unless project.present?

   (project.draws.pluck(:index).sort.last || 0) + 1
  end

  def budget_variance
    # TODO from approved draw costs
    123.45
  end

  def over_budget?
    budget_variance > 0
  end

  def approve(user)
    self.approver = user
    self.approved_at = Time.current
    save
  end

  def assign_reference?
    approved? 
  end

  def active_organization_requests(organization)
    draw_cost_requests.where(draw: self, organization: organization, state: DrawCostRequest::EXISTING_STATES)
  end

  def active_requests_for?(obj)
    org = case obj
          when Organization
            obj
          when User
            obj.organization
          else
            return false
          end
    active_organization_requests(org).any?
  end

  def provisional_request_total_for(organization)
    draw_cost_requests.
      visible.
      where(organization: organization).
      map(&:provisional_total).
      sum
  end

  def request_total_for(organization)
    draw_cost_requests.
      approved.
      where(organization: organization).
      sum(:total)
  end

end
