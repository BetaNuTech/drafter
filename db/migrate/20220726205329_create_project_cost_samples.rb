class CreateProjectCostSamples < ActiveRecord::Migration[7.0]
  def change
    create_table :project_cost_samples, id: :uuid do |t|
      t.string :name, null: false
      t.integer :cost_type, null: false
      t.integer :approval_lead_time
      t.boolean :standard, null: false, default: true

      t.timestamps
    end

    add_index :project_cost_samples, [ :name, :standard ], name: 'project_cost_samples_idx'
  end
end
