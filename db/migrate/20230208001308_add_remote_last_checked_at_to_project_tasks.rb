class AddRemoteLastCheckedAtToProjectTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :project_tasks, :remote_last_checked_at, :datetime
    remove_index :project_tasks, name: 'idx_project_tasks_remote'
    add_index  :project_tasks, [:remoteid, :remote_updated_at, :remote_last_checked_at], name: 'idx_project_tasks_remote'
  end
end
