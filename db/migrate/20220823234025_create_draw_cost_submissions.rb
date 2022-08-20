class CreateDrawCostSubmissions < ActiveRecord::Migration[7.0]
  def change
    create_table :draw_cost_submissions, id: :uuid do |t|
      t.references :draw_cost_request, foreign_key: true, type: :uuid
      t.references :approver, foreign_key: {to_table: :users}, type: :uuid
      t.boolean :audit, null: false, default: false
      t.boolean :manual_approval_required, null: false, default: false
      t.boolean :multi_invoice, null: false, default: false
      t.boolean :ocr_approval
      t.date :approval_due_date
      t.date :approved_at
      t.decimal :amount, null: false, default: 0.0
      t.string :state, null: false, default: 'pending'

      t.timestamps
    end
  end
end
