# == Schema Information
#
# Table name: project_users
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  project_id      :uuid             not null
#  project_role_id :uuid             not null
#  user_id         :uuid             not null
#
# Indexes
#
#  index_project_users_on_project_id       (project_id)
#  index_project_users_on_project_role_id  (project_role_id)
#  index_project_users_on_user_id          (user_id)
#  project_users_idx                       (project_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (project_role_id => project_roles.id)
#  fk_rails_...  (user_id => users.id)
#
class ProjectUser < ApplicationRecord
  belongs_to :project
  belongs_to :project_role
  belongs_to :user

  validates :project_id, presence: true
  validates :project_role_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :project_id} 

  def available_users
    project.present? ? project&.available_users.ordered_by_name : []
  end

  def available_roles
    ProjectRole.in_order_of(:slug, ProjectRole::HIERARCHY)
  end

  def name
    user&.name || 'UNKNOWN'
  end
end
