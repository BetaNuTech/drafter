class CreateRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :roles, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, unique: true
      t.text :description

      t.timestamps
    end

    add_reference :users, :role, null: false, foreign_key: true, type: :uuid
    add_index :roles, :slug, unique: true
  end
end
