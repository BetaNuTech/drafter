class RemoveConsultantRole < ActiveRecord::Migration[7.0]
  def change
    ProjectRole.where(slug: :consultant).destroy_all
  end
end
