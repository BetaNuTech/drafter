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
#  index_draws_on_project_id            (project_id)
#  index_draws_on_project_id_and_index  (project_id,index) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
require 'rails_helper'

RSpec.describe Draw, type: :model do
  include_context 'projects'

  describe 'initialization' do
    it 'creates a new draw' do
      expect {
        create(:draw, project: project1)
      }.to change{Draw.count}.by(1)
    end
  end

  describe 'naming/index' do
    it 'has a unique index for a given project' do
      draw1 = create(:draw, project: project1, index: 1)
      draw2 = build(:draw, project: project1, index: 1)
      refute(draw2.save)
      draw2.index = 2
      assert(draw2.save)
    end

    it 'returns the next draw number' do
      draw1 = create(:draw, project: project1, index: 1)
      draw2 = create(:draw, project: project1, index: 2)
      draw3 = build(:draw, project: project1)
      expect(draw3.next_index).to eq(3)
    end
  end

  describe 'budget' do
    it 'returns budget variance'
    it 'returns if over budget'
  end
end
