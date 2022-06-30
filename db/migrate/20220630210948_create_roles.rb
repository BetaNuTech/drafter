class CreateRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :roles, id: :uuid do |t|
      t.string :name
      t.string :slug, unique: true
      t.text :description

      t.timestamps
    end
  end
end
