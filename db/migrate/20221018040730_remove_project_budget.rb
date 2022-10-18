class RemoveProjectBudget < ActiveRecord::Migration[7.0]
  def change
    remove_column :projects, :budget
  end
end
