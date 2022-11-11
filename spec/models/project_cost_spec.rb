require 'rails_helper'

RSpec.describe ProjectCost, type: :model do
  include_context 'sample_draws'

  describe 'initialization' do
    it 'creates a ProjectCost' do
      project_cost = build(:project_cost)
      assert(project_cost).save
    end
  end

  describe 'totals' do
    before do
      draw_cost
      draw_cost_invoices
      draw_cost2
      draw_cost2_invoices
    end
    describe 'returns total value of change orders' do
    end
  end



end
