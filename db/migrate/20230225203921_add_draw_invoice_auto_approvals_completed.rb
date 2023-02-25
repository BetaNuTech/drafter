class AddDrawInvoiceAutoApprovalsCompleted < ActiveRecord::Migration[7.0]
  def change
    add_column :draws, :invoice_auto_approvals_completed, :boolean, default: false
    add_index :draws, [:state, :invoice_auto_approvals_completed], name: 'draws_auto_approval_idx'
  end
end
