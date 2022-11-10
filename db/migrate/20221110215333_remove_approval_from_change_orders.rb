class RemoveApprovalFromChangeOrders < ActiveRecord::Migration[7.0]
  def change
    remove_column :change_orders, :state
    remove_column :change_orders, :approved_by_id
    remove_column :change_orders, :approved_by_desc
    remove_column :change_orders, :approved_at
  end
end
