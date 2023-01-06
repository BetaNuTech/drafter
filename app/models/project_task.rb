# == Schema Information
#
# Table name: project_tasks
#
#  id             :uuid             not null, primary key
#  approver_name  :string
#  assignee_name  :string
#  attachment_url :string
#  completed_at   :datetime
#  description    :text             not null
#  due_at         :datetime
#  name           :string           not null
#  notes          :text
#  origin_type    :string
#  preview_url    :string
#  remoteid       :string
#  reviewed_at    :datetime
#  state          :string           default("new"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  approver_id    :uuid
#  assignee_id    :uuid
#  origin_id      :uuid
#  project_id     :uuid             not null
#
# Indexes
#
#  idx_project_tasks_general           (project_id,assignee_id,approver_id,state)
#  idx_project_tasks_origin            (origin_type,origin_id)
#  index_project_tasks_on_approver_id  (approver_id)
#  index_project_tasks_on_assignee_id  (assignee_id)
#  index_project_tasks_on_origin       (origin_type,origin_id)
#  index_project_tasks_on_project_id   (project_id)
#  index_project_tasks_on_remoteid     (remoteid)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (project_id => projects.id)
#
class ProjectTask < ApplicationRecord
  ### Concerns
  include ProjectTasks::StateMachine

  ### Associations
  belongs_to :approver, class_name: 'User', optional: true
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :origin, polymorphic: true, optional: true
  belongs_to :project

  ### Validations
  validates :name, presence: true
  validates :description, presence: true

  ### Scopes
  scope :pending, -> { where(state: ProjectTasks::StateMachine::PENDING_STATES) }

  ### Broadcast Streams
  after_create_commit -> (project_task) {
    stream_name = target =  "Project_#{project_task.project_id}_project_tasks"
    broadcast_prepend_to stream_name,
                         partial: "project_tasks/project_task",
                         locals: {project_task: self},
                         target: target
  }

  after_destroy_commit -> (project_task) {
    stream_name = target =  "Project_#{project_task.project_id}_project_tasks"
    broadcast_remove_to stream_name, target: target
  }

  after_update_commit -> (project_task) {
    stream_name = "Project_#{project_task.project_id}_project_tasks"
    target = "project_task_#{project_task.id}"
    case project_task.state
      when *ProjectTasks::StateMachine::PENDING_STATES
        broadcast_replace_to stream_name,
                         partial: "project_tasks/project_task",
                         locals: {project_task: self},
                         target: target
      else
        broadcast_remove_to stream_name, target: target
    end
  }
end
