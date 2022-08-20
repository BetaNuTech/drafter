FactoryBot.define do
  factory :draw_cost_request do
    association :organization
    association :draw_cost
    association :draw
    association :user
    alert { 'ok' }
    amount { 1234.0 }
    approval_due_date { Time.current + 10.days }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    state { 'pending' }
    total { 1234.0 }
  end
end
