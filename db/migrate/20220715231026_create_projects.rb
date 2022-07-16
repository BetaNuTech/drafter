class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :budget, null: false, default: 0.0
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
