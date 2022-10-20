# == Schema Information
#
# Table name: project_cost_samples
#
#  id                 :uuid             not null, primary key
#  approval_lead_time :integer
#  change_requestable :boolean          default(TRUE)
#  cost_type          :integer          not null
#  drawable           :boolean          default(TRUE)
#  name               :string           not null
#  standard           :boolean          default(TRUE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  project_cost_samples_idx  (drawable,change_requestable,standard,name)
#
class ProjectCostSample < ApplicationRecord
  include Seeds::Seedable

  COST_TYPES = %w{land hard soft finance}

  ### Enums
  enum cost_type: COST_TYPES

  ### Validations
  validates :name, presence: true
  validates :cost_type, presence: true

  ### Scopes
  scope :standard, -> { where(standard: true) }
  scope :drawable, -> { where(drawable: true) }
  scope :change_requestable, -> { where(change_requestable: true) }
end
