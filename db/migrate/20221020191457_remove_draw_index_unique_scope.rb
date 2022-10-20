class RemoveDrawIndexUniqueScope < ActiveRecord::Migration[7.0]
  def change
    remove_index :draws, [:project_id, :organization_id, :index]
  end
end
