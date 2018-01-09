# == Schema Information
#
# Table name: lead_sources
#
#  id         :uuid             not null, primary key
#  name       :string
#  incoming   :boolean
#  slug       :string
#  active     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  api_token  :string
#

FactoryBot.define do
  factory :lead_source do
    name { Faker::Company.name }
    incoming true
    slug { Faker::Company.ein }
    active true

    factory :druid_source do
      name 'Druid WebApp'
      incoming true
      slug 'druid'
      active 'true'
    end

    factory :zillow_source do
      name 'Zillow'
      incoming true
      slug 'zillow'
      active true
    end
  end
end
