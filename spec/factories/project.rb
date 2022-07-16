FactoryBot.define do
  factory :project do
    name { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
  end
end
