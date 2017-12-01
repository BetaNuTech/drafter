# == Schema Information
#
# Table name: leads
#
#  id             :uuid             not null, primary key
#  user_id        :uuid
#  lead_source_id :uuid
#  title          :string
#  first_name     :string
#  last_name      :string
#  referral       :string
#  state          :string
#  notes          :text
#  first_comm     :datetime
#  last_comm      :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryBot.define do
  factory :lead do
    title 'Ms.'
    first_name 'Jane'
    last_name 'Doe'
    referral 'Newspaper'
    state 'active'
    notes 'This is a property lead'
    first_comm { DateTime.now }
    last_comm { DateTime.now }

    factory :lead_with_preference do
      after(:create) do |lead|
        create(:lead_preference, lead: lead)
      end
    end

  end
end
