class AddTotalToProjectCostSamples < ActiveRecord::Migration[7.0]
  def change
    add_column :project_cost_samples, :total, :decimal, null: false, default: 0.0
  end
end
