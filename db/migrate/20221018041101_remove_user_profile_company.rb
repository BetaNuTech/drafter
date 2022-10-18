class RemoveUserProfileCompany < ActiveRecord::Migration[7.0]
  def change
    remove_column :user_profiles, :company
  end
end
