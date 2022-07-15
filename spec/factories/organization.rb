FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
  end
end
