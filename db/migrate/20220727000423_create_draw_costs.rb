class CreateDrawCosts < ActiveRecord::Migration[7.0]
  def change
    create_table :draw_costs, id: :uuid do |t|
      t.uuid :draw_id, null: false
      t.integer :cost_type, null: false
      t.string :name, null: false
      t.string :state, null: false, default: 'pending'
      t.integer :approval_lead_time, null: false, default: 0
      t.decimal :total, null: false, default: 0.0

      t.timestamps
    end

    add_index :draw_costs, [:draw_id, :state], name: 'draw_costs_idx'
  end
end
