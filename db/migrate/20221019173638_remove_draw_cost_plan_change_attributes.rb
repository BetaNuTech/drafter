class RemoveDrawCostPlanChangeAttributes < ActiveRecord::Migration[7.0]
  def change
    remove_index :draw_costs, :approver_id
    remove_index :draw_costs, :plan_change_approver_id
    remove_column :draw_costs, :contingency
    remove_column :draw_costs, :plan_change
    remove_column :draw_costs, :plan_change_desc
    remove_column :draw_costs, :plan_change_approved_at
    remove_column :draw_costs, :plan_change_approver_id
    remove_column :draw_costs, :plan_change_approved_by_desc
  end
end
