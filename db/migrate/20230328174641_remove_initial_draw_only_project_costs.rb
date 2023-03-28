class RemoveInitialDrawOnlyProjectCosts < ActiveRecord::Migration[7.0]
  def change
    remove_column :project_cost_samples, :initial_draw_only
    remove_index :project_costs, name: 'project_costs_drawable_idx'
    remove_column :project_costs, :initial_draw_only
    add_index :project_costs, [ :drawable, :change_requestable, :change_request_allowed ], name: 'project_costs_drawable_idx'
  end
end
