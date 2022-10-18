# == Schema Information
#
# Table name: draw_costs
#
#  id              :uuid             not null, primary key
#  approved_at     :datetime
#  state           :string           default("pending"), not null
#  total           :decimal(, )      default(0.0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  approver_id     :uuid
#  draw_id         :uuid             not null
#  project_cost_id :uuid             not null
#
# Indexes
#
#  draw_costs_assoc_idx                 (draw_id,project_cost_id,approver_id)
#  draw_costs_draw_state_idx            (draw_id,state)
#  index_draw_costs_on_draw_id          (draw_id)
#  index_draw_costs_on_project_cost_id  (project_cost_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (draw_id => draws.id)
#  fk_rails_...  (project_cost_id => project_costs.id)
#
require 'rails_helper'

RSpec.describe DrawCost, type: :model do
  include_context 'sample_projects'

  describe 'initialization' do
    it 'creates a DrawCost' do
      draw = sample_project.draws.first
      draw_cost = build(:draw_cost, draw: draw, project_cost: sample_project.project_costs.first)
      assert(draw_cost.save)
    end
  end

  describe 'view helpers' do
    it 'returns the css class for the cost type' do
      draw_cost = build(:draw_cost, draw: sample_project.draws.first)
      expect(draw_cost.state_css_class).to eq('secondary')
    end
  end
  
end
