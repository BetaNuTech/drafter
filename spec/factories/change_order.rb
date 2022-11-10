FactoryBot.define do
  factory :change_order do
    association :project_cost
    association :draw_cost
    association :funding_source, factory: :project_cost
    amount { Faker::Commerce.price }
  end
end
