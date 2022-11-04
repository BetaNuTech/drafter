class Rename < ActiveRecord::Migration[7.0]
  def change
    rename_column :change_orders, :integration_attemp_number, :integration_attempt_number
  end
end
