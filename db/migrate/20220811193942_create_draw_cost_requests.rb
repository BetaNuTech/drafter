class CreateDrawCostRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :draw_cost_requests, id: :uuid do |t|
      t.references :draw, null: false, foreign_key: true, type: :uuid
      t.references :draw_cost, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.string :state, null: false, default: 'pending'
      t.decimal :amount, null: false, default: 0.0
      t.decimal :total, null: false, default: 0.0
      t.text :description
      t.boolean :plan_change, null: false, default: false
      t.text :plan_change_reason
      t.integer :alert, null: false, default: 0
      t.boolean :audit, null: false, default: false
      t.date :approval_due_date
      t.uuid :approver_id
      t.datetime :approved_at

      t.timestamps
    end
  end
end
