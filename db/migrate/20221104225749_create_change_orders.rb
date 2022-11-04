class CreateChangeOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :change_orders, id: :uuid do |t|
      t.references :project_cost, null: false, foreign_key: true, type: :uuid
      t.references :draw_cost, null: false, foreign_key: true, type: :uuid
      t.references :funding_source, null: false, foreign_key: { to_table: :project_costs }, type: :uuid
      t.references :approved_by, foreign_key: { to_table: :users }, type: :uuid
      t.decimal :amount
      t.text :description
      t.datetime :approved_at
      t.string :approved_by_desc
      t.string :external_task_id
      t.datetime :integration_attempt_at
      t.integer :integration_attemp_number
      t.string :state

      t.timestamps
    end
  end
end
