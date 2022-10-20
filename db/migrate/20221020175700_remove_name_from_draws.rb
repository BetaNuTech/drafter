class RemoveNameFromDraws < ActiveRecord::Migration[7.0]
  def change
    remove_column :draws, :name
  end
end
