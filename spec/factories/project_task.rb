FactoryBot.define do
  factory :project_task do
    association :project
    association :assignee, factory: :user
    association :approver, factory: :user
    association :origin, factory: :invoice
    state { 'new' }
    name { Faker::Lorem.sentence }
    description { Faker::Lorem.sentence }
    attachment_url { Faker::Internet.url }
    preview_url { Faker::Internet.url }
    remoteid { nil }
    approver_name { Faker::Name.name }
    assignee_name { Faker::Name.name }
    due_at { 2.days.from_now }
    completed_at { nil }
  end
end
