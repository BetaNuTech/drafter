class CreateDrawCosts < ActiveRecord::Migration[7.0]
  def change
    create_table :draw_costs, id: :uuid do |t|
      t.references :draw, null: false, foreign_key: true, type: :uuid
      t.references :project_cost, null: false, foreign_key: true, type: :uuid
      t.references :approver, foreign_key: { to_table: :users }, type: :uuid
      t.references :plan_change_approver, foreign_key: { to_table: :users }, type: :uuid
      t.decimal :total, null: false, default: 0.0
      t.decimal :contingency, null: false, default: 0.0
      t.string :state, null: false, default: 'pending'
      t.datetime :approved_at
      t.boolean :plan_change, null: false, default: false
      t.datetime :plan_change_approved_at
      t.text :plan_change_desc
      t.text :plan_change_approved_by_desc

      t.timestamps
    end

    add_index :draw_costs, [:draw_id, :state], name: 'draw_costs_draw_state_idx'
    add_index :draw_costs, [:draw_id, :project_cost_id, :approver_id], name: 'draw_costs_assoc_idx'
  end
end
