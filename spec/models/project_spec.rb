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
end
