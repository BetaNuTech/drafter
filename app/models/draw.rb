# == Schema Information
#
# Table name: draws
#
#  id              :uuid             not null, primary key
#  amount          :decimal(, )      default(0.0), not null
#  approved_at     :datetime
#  index           :integer          default(1), not null
#  name            :string           not null
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
#  draws_assoc_idx                                          (project_id,user_id,organization_id,approver_id,state)
#  index_draws_on_approver_id                               (approver_id)
#  index_draws_on_organization_id                           (organization_id)
#  index_draws_on_project_id                                (project_id)
#  index_draws_on_project_id_and_organization_id_and_index  (project_id,organization_id,index) UNIQUE
#  index_draws_on_user_id                                   (user_id)
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

  ### Params
  ALLOWED_PARAMS = [:name, :amount, :notes ]

  ### Scopes
  scope :for_organization, -> (organization) { where(organization: organization) }

  ### Associations
  belongs_to :project
  belongs_to :organization
  belongs_to :user
  belongs_to :approver, class_name: 'User', optional: true
  has_many :draw_costs, dependent: :destroy
  has_many :draw_documents, dependent: :destroy

  ### Validations
  validates :name, presence: true, uniqueness: {scope: [:organization_id, :project_id ]}, allow_blank: false
  validates :index, presence: true, numericality: { greater_than_or_equal_to: 1}, uniqueness: {scope: [ :project_id, :organization_id ]}
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0.0}
  validates :state, presence: true

  def next_index
    return 1 unless project.present?

   (project.draws.for_organization(organization).pluck(:index).sort.last || 0) + 1
  end

  def budget_variance
    draw_costs.sum(:total) - amount
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
    #draw_costs.where(draw: self, organization: organization, state: DrawCost::EXISTING_STATES)
    []
  end

  def active_requests_for?(obj)
    #org = case obj
          #when Organization
            #obj
          #when User
            #obj.organization
          #else
            #return false
          #end
    #active_organization_requests(org).any?
    []
  end

  def provisional_request_total_for(organization)
    #draw_costs.
      #visible.
      #where(organization: organization).
      #map(&:provisional_total).
      #sum
    0.0
  end

  def request_total_for(organization)
    #draw_costs.
      #approved.
      #where(organization: organization).
      #sum(:total)
    0.0
  end

end
