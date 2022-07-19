class CreateProjectUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :project_users, id: :uuid do |t|
      t.uuid :project_id, null: false
      t.uuid :user_id, null: false
      t.uuid :project_role_id, null: false

      t.timestamps
    end

    add_index :project_users, [:project_id, :user_id, :project_role_id], name: 'project_users_idx', unique: true
  end
end
