# == Schema Information
#
# Table name: draws
#
#  id              :uuid             not null, primary key
#  amount          :decimal(, )      default(0.0), not null
#  approved_at     :datetime
#  index           :integer          default(1), not null
#  notes           :text
#  reference       :string
#  state           :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  approver_id     :uuid
#  organization_id :uuid             not null
#  project_id      :uuid             not null
#  user_id         :uuid             not null
#
# Indexes
#
#  draws_assoc_idx                 (project_id,user_id,organization_id,approver_id,state)
#  index_draws_on_approver_id      (approver_id)
#  index_draws_on_organization_id  (organization_id)
#  index_draws_on_project_id       (project_id)
#  index_draws_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approver_id => users.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Draw, type: :model do
  include_context 'projects'
  include_context 'sample_projects'
  include_context 'organizations'

  describe 'initialization' do
    it 'creates a new draw' do
      expect {
        create(:draw, project: project1)
      }.to change{Draw.count}.by(1)
    end
  end

  describe 'naming/index' do
    it 'returns the next draw number' do
      draw1 = create(:draw, project: sample_project, index: 1, organization: organization1)
      draw2 = create(:draw, project: sample_project, index: 2, organization: organization1)
      draw3 = Draw.new(amount: 123.45, project: sample_project, organization: organization1, user: sample_project.developers.first )
      expect(draw3.next_index).to eq(3)
      expect(draw3.index).to eq(3)
    end
  end

  describe 'budget' do
    it 'returns budget variance'
    it 'returns if over budget'
  end
end
