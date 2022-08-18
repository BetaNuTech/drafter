class CreateOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations, id: :uuid do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_reference :users, :organization, null: true, foreign_key: true, type: :uuid
  end
end
