class AddStateToDrawDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :draw_documents, :state, :string, default: :pending
    add_index :draw_documents, :state
  end
end
