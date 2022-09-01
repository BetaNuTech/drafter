class CreateDrawCostDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :draw_cost_documents, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.references :draw_cost_request, null: false, foreign_key: true, type: :uuid
      t.text :notes
      t.integer :documenttype, null: false, default: 0
      t.date :approval_due_date
      t.datetime :approved_at
      t.references :approver, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end
  end
end
