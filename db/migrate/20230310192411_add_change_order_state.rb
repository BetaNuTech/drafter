class AddChangeOrderState < ActiveRecord::Migration[7.0]
  def change
    add_column :change_orders, :state, :string, default: :pending
    remove_index :change_orders, :draw_cost_id
    add_index :change_orders, [:draw_cost_id, :state ]
  end
end
