FactoryBot.define do
  factory :draw_cost_submission do
    association :draw_cost_request
    amount { Faker::Number.decimal(l_digits: 3, r_digits: 2)}
    audit { false }
    manual_approval_required { false }
    multi_invoice { false }
    ocr_approval { false }
    state { 'pending' }
  end
end
