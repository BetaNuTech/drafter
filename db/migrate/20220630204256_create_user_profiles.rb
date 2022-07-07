class CreateUserProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :user_profiles, id: :uuid do |t|
      t.uuid :user_id
      t.string :name_prefix
      t.string :first_name
      t.string :last_name
      t.string :name_suffix
      t.string :company
      t.string :title
      t.string :phone
      t.text :notes
      t.jsonb :appsettings

      t.timestamps
    end

    add_index :user_profiles, :user_id, unique: true
  end
end
