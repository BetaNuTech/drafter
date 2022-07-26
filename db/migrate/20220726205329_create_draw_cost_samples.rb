class CreateDrawCostSamples < ActiveRecord::Migration[7.0]
  def change
    create_table :draw_cost_samples, id: :uuid do |t|
      t.string :name, null: false
      t.integer :cost_type, null: false
      t.integer :approval_lead_time
      t.boolean :standard, null: false, default: true

      t.timestamps
    end

    add_index :draw_cost_samples, [ :name, :standard ], name: 'draw_cost_samples_idx'
  end
end
