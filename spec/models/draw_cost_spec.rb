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
#  draw_costs_idx               (draw_id,state)
#  index_draw_costs_on_draw_id  (draw_id)
#
# Foreign Keys
#
#  fk_rails_...  (draw_id => draws.id)
#
require 'rails_helper'

RSpec.describe DrawCost, type: :model do
  include_context 'sample_projects'

  describe 'initialization' do
    it 'creates a DrawCost' do
      draw = sample_project.draws.first
      draw_cost = build(:draw_cost, draw: draw)
      assert(draw_cost.save)
    end
  end

  describe 'view helpers' do
    it 'returns the css class for the cost type' do
      draw_cost = build(:draw_cost, draw: sample_project.draws.first, cost_type: 'land')
      expect(draw_cost.cost_type_css_class).to eq('secondary')
    end
  end
  
end
