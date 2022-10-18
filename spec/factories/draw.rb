FactoryBot.define do
  factory :draw do
    association :project
    association :user
    association :organization
    sequence(:index)
    sequence(:name) { |n| "Draw #{n}"}
    notes { Faker::Lorem.paragraph(sentence_count: 3)}
    reference { Faker::Alphanumeric.alphanumeric(number: 10) }
    state { 'pending' }
  end
end
