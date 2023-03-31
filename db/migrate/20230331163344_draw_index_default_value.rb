class DrawIndexDefaultValue < ActiveRecord::Migration[7.0]
  def change
    change_column_default :draws, :index, from: 1, to: 0
  end
end
