# == Schema Information
#
# Table name: draws
#
#  id         :uuid             not null, primary key
#  approver   :uuid
#  index      :integer          default(1), not null
#  name       :string           not null
#  notes      :text
#  reference  :string
#  state      :string           default("pending"), not null
#  total      :decimal(, )
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :uuid             not null
#
# Indexes
#
#  index_draws_on_project_id_and_index  (project_id,index) UNIQUE
#
class Draw < ApplicationRecord

  ### Params
  ALLOWED_PARAMS = [:project_id, :name, :notes, :reference, :total]

  ### Associations
  belongs_to :project
end
