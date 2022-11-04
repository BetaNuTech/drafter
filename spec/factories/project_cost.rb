FactoryBot.define do
  factory :project_cost do
    association :project
    name { Faker::Lorem.sentence }
    total { Faker::Commerce.price }
    cost_type { 'land' }
  end
end
