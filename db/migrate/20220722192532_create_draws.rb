class CreateDraws < ActiveRecord::Migration[7.0]
  def change
    create_table :draws, id: :uuid do |t|
      t.uuid :project_id
      t.integer :index
      t.string :name
      t.string :state
      t.string :reference
      t.decimal :total
      t.uuid :approver
      t.text :notes

      t.timestamps
    end
  end
end
