# == Schema Information
#
# Table name: organizations
#
#  id          :uuid             not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe "Initialization" do
    it 'creates a new organization' do
      organization = build(:organization)
      assert(organization.save)
    end
  end
end
