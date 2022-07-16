require 'rails_helper'

RSpec.describe Project, type: :model do
  describe "Initialization" do
    it 'creates a new project' do
      project = build(:project)
      assert(project.save)
    end
  end
end
