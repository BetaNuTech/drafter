class CreateOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations, id: :uuid do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    add_column :users, :organization_id, :uuid
  end
end
