FactoryBot.define do
  factory :invoice do
    association :draw_cost
    association :user
    amount { Faker::Commerce.price }
  end
end
