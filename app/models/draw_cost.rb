# == Schema Information
#
# Table name: draw_costs
#
#  id                 :uuid             not null, primary key
#  approval_lead_time :integer          default(0), not null
#  cost_type          :integer          not null
#  name               :string           not null
#  state              :string           default("pending"), not null
#  total              :decimal(, )      default(0.0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  draw_id            :uuid             not null
#
# Indexes
#
#  draw_costs_idx  (draw_id,state)
#
class DrawCost < ApplicationRecord
  ### Associations
  belongs_to :draw

  ### Validations
  validates :approval_lead_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cost_type, presence: true
  validates :name, presence: true
  validates :state, presence: true
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0.0 }
end
