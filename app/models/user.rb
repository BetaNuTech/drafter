# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  active                 :boolean          default(TRUE), not null
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  timezone               :string           default("Pacific Time (US & Canada)"), not null
#  unconfirmed_email      :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  organization_id        :uuid
#  role_id                :uuid             not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_organization_id       (organization_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_role_id               (role_id)
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (role_id => roles.id)
#
class User < ApplicationRecord
  include Users::Devise
  include Users::Profile
  include Users::Projects
  include Users::Role

  ALLOWED_PARAMS = [:id, :email, :timezone, :password, :password_confirmation ]

  validates :email, uniqueness: true, presence: true
  validates :role_id, presence: true
  belongs_to :organization, required: false
  has_many :approved_tasks, foreign_key: 'approver_id', class_name: 'ProjectTask', dependent: :destroy
  has_many :assigned_tasks, foreign_key: 'assignee_id', class_name: 'ProjectTask', dependent: :destroy

  scope :ordered_by_name, -> { includes(:profile).order("user_profiles.last_name ASC, user_profiles.first_name ASC")}
  scope :active, -> { where(active: true) }

  def deactivated?
    !active?
  end

  def full_role_desc(project)
    "#{name}: #{role.name} User and #{project_role(project)&.name || 'UNROLED'} for '#{project.name}'"
  end

  def name_with_organization
    if organization
      name + "(#{organization.name})" 
    else
      name + "(NO ORG)"
    end
  end

end
