class AddRemoteUpdatedAtToProjectTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :project_tasks, :remote_updated_at, :datetime
    remove_index :project_tasks, :remoteid
    add_index :project_tasks, [:remoteid, :remote_updated_at], name: 'idx_project_tasks_remote'
  end
end
