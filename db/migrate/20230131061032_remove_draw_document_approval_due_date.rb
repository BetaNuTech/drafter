class RemoveDrawDocumentApprovalDueDate < ActiveRecord::Migration[7.0]
  def change
    remove_column :draw_documents, :approval_due_date
  end
end
