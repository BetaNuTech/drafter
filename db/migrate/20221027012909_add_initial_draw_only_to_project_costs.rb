class AddInitialDrawOnlyToProjectCosts < ActiveRecord::Migration[7.0]
  def change
    add_column :project_costs, :initial_draw_only, :boolean, default: false
    add_column :project_costs, :change_request_allowed, :boolean, default: true
    remove_index :project_cost_samples, name: 'project_costs_drawable_idx'
    add_index :project_costs, [ :drawable, :change_requestable, :initial_draw_only, :change_request_allowed ], name: 'project_costs_drawable_idx'

    add_column :project_cost_samples, :initial_draw_only, :boolean, default: false
    add_column :project_cost_samples, :change_request_allowed, :boolean, default: true
    remove_index :project_cost_samples, name: 'project_cost_samples_idx'
    add_index :project_cost_samples, [ :standard, :name ], name: 'project_cost_samples_idx'
  end
end
