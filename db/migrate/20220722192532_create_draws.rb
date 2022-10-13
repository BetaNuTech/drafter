class CreateDraws < ActiveRecord::Migration[7.0]
  def change
    create_table :draws, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :approver, foreign_key: { to_table: :users }, type: :uuid
      t.string :name, null: false
      t.integer :index, null: false, default: 1
      t.decimal :amount, null: false, default: 0.0
      t.string :state, null: false, default: 'pending'
      t.string :reference
      t.datetime :approved_at
      t.text :notes

      t.timestamps
    end

    add_index :draws, [:project_id, :user_id, :organization_id, :approver_id, :state ], name: 'draws_assoc_idx'
    add_index :draws, [:project_id, :organization_id, :index], unique: true
  end
end
