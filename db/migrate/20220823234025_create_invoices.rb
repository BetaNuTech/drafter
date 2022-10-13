class CreateInvoices < ActiveRecord::Migration[7.0]
  def change
    create_table :invoices, id: :uuid do |t|
      t.references :draw_cost, foreign_key: true, type: :uuid
      t.references :user, foreign_key: true, type: :uuid
      t.references :approver, foreign_key: { to_table: :users }, type: :uuid
      t.string :state, null: false, default: 'pending'
      t.string :description
      t.decimal :amount, null: false, default: 0.0
      t.boolean :manual_approval_required, null: false, default: true
      t.boolean :audit, null: false, default: false
      t.boolean :multi_invoice
      t.datetime :approved_at
      t.string :approved_by_desc
      t.decimal :ocr_amount
      t.datetime :ocr_processed
      t.json :ocr_data

      t.timestamps
    end

    add_index :invoices, [ :draw_cost_id, :user_id, :approver_id ], name: 'invoices_assoc_idx'
    add_index :invoices, [ :state, :audit, :manual_approval_required, :ocr_processed ], name: 'invoices_state_idx'
  end
end
