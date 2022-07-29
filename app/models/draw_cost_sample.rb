# == Schema Information
#
# Table name: draw_cost_samples
#
#  id                 :uuid             not null, primary key
#  approval_lead_time :integer
#  cost_type          :integer          not null
#  name               :string           not null
#  standard           :boolean          default(TRUE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  draw_cost_samples_idx  (name,standard)
#
class DrawCostSample < ApplicationRecord
  include Seeds::Seedable

  COST_TYPES = %w{land hard soft finance}

  ### Enums
  enum cost_type: COST_TYPES

  ### Validations
  validates :name, presence: true
  validates :cost_type, presence: true

  ### Scopes
  scope :standard, -> { where(standard: true) }
end
