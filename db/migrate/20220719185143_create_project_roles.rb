class CreateProjectRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :project_roles, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end
    add_index :project_roles, :slug
  end
end
