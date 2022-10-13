class CreateProjectCosts < ActiveRecord::Migration[7.0]
  def change
    create_table :project_costs, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.integer :cost_type, null: false
      t.string :name, null: false
      t.string :state, null: false, default: 'pending'
      t.integer :approval_lead_time, null: false, default: 0
      t.decimal :total, null: false, default: 0.0

      t.timestamps
    end

    add_index :project_costs, [:project_id, :state], name: 'project_costs_project_idx'
  end
end
