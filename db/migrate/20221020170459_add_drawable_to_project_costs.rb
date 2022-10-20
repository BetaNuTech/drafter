class AddDrawableToProjectCosts < ActiveRecord::Migration[7.0]
  def change
    add_column :project_costs, :drawable, :boolean, default: true
    add_column :project_costs, :change_requestable, :boolean, default: true
    add_index :project_costs, [ :drawable, :change_requestable ], name: 'project_costs_drawable_idx'
    rename_index :project_costs, :draw_costs_project_idx, :project_costs_project_idx

    add_column :project_cost_samples, :drawable, :boolean, default: true
    add_column :project_cost_samples, :change_requestable, :boolean, default: true
    remove_index :project_cost_samples, name: 'project_cost_samples_idx'
    add_index :project_cost_samples, [ :drawable, :change_requestable, :standard, :name ], name: 'project_cost_samples_idx'
  end
end
