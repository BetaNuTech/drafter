FactoryBot.define do
  factory :project_role do
    name { Faker::Lorem.word }
    slug  { Faker::Lorem.word }
    description { Faker::Lorem.sentence }

    factory :owner_project_role do
      name { 'Owner' }
      slug { 'owner' }
      description { 'owner role' }
    end

    factory :manager_project_role do
      name { 'Manager' }
      slug { 'manager' }
      description { 'manager role' }
    end

    factory :finance_project_role do
      name { 'Finance' }
      slug { 'finance' }
      description { 'finance role' }
    end

    factory :investor_project_role do
      name { 'investor' }
      slug { 'investor' }
      description { 'investor role' }
    end

    factory :developer_project_role do
      name { 'Developer' }
      slug { 'developer' }
      description { 'developer role' }
    end
  end
end
