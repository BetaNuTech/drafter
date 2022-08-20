FactoryBot.define do
  factory :draw do
    association :project
    sequence(:index)
    sequence(:name) { |n| "Draw #{n}"}
    notes { Faker::Lorem.paragraph(sentence_count: 3)}
    reference { Faker::Alphanumeric.alphanumeric(number: 10) }
    state { 'pending' }
    total { Faker::Number.decimal(l_digits: 5, r_digits: 2) }
  end
end
