class CreateDraws < ActiveRecord::Migration[7.0]
  def change
    create_table :draws, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.integer :index, null: false, default: 1
      t.string :name, null: false
      t.string :state, null: false, default: 'pending'
      t.string :reference
      t.decimal :total
      t.uuid :approver
      t.text :notes

      t.timestamps
    end

    add_index :draws, [:project_id, :index], unique: true
  end
end
