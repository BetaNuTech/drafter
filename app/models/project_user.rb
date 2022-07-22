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
#  project_users_idx  (project_id,user_id,project_role_id) UNIQUE
#
class ProjectUser < ApplicationRecord
  belongs_to :project
  belongs_to :project_role
  belongs_to :user

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
