require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe "Initialization" do
    it 'creates a new organization' do
      organization = build(:organization)
      assert(organization.save)
    end
  end
end
