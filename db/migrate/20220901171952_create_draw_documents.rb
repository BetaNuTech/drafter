class CreateDrawDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :draw_documents, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.references :draw, null: false, foreign_key: true, type: :uuid
      t.references :approver, foreign_key: { to_table: :users }, type: :uuid
      t.text :notes
      t.integer :documenttype, null: false, default: 0
      t.date :approval_due_date
      t.datetime :approved_at

      t.timestamps
    end

    add_index :draw_documents, [:draw_id, :user_id], name: 'draw_documents_assoc_idx'
    add_index :draw_documents, :documenttype
  end
end
