# == Schema Information
#
# Table name: projects
#
#  id          :uuid             not null, primary key
#  active      :boolean          default(TRUE), not null
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Project, type: :model do
  describe "Initialization" do
    it 'creates a new project' do
      project = build(:project)
      assert(project.save)
    end
  end

  describe 'helpers' do
    include_context 'sample_projects'

    it 'returns whether project costs can be changed' do
      assert(sample_project.allow_project_cost_changes?)
      draw = create(:draw, project: sample_project, state: 'submitted', index: 10)
      sample_project.reload
      assert(sample_project.allow_project_cost_changes?)
      draw.state = 'funded'
      draw.save!
      sample_project.reload
      refute(sample_project.allow_project_cost_changes?)
    end
  end
end
