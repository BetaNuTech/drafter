FactoryBot.define do
  factory :draw_cost do
    association :draw
    state { 'pending' }
    total { 12345.0 }
  end
end
