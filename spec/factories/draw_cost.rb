FactoryBot.define do
  factory :draw_cost do
    association :draw
    approval_lead_time { 10 }
    cost_type { :land }
    name { Faker::Lorem.sentence }
    state { 'pending' }
    total { 12345.0 }
  end
end
