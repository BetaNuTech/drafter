class CreateProjectTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :project_tasks, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.references :origin, polymorphic: true, type: :uuid
      t.references :assignee, foreign_key: {to_table: :users}, type: :uuid
      t.references :approver, foreign_key: {to_table: :users}, type: :uuid
      t.string :state, null: false, default: 'new'
      t.string :remoteid
      t.string :name, null: false
      t.string :assignee_name
      t.string :approver_name
      t.string :attachment_url
      t.string :preview_url
      t.datetime :reviewed_at
      t.datetime :due_at
      t.datetime :completed_at
      t.text :description, null: false
      t.text :notes
      t.timestamps
    end

    add_index :project_tasks, [:project_id, :assignee_id, :approver_id, :state], name: 'idx_project_tasks_general'
    add_index :project_tasks, :remoteid
    add_index :project_tasks, [:origin_type, :origin_id], name: 'idx_project_tasks_origin'
  end
end
