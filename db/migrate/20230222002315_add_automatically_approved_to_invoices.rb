class AddAutomaticallyApprovedToInvoices < ActiveRecord::Migration[7.0]
  def change
    add_column :invoices, :automatically_approved, :boolean, default: false
  end
end
