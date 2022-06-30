FactoryBot.define do
  factory :role do
    name { Faker::Lorem.word }
    slug  { Faker::Lorem.word }
    description { Faker::Lorem.sentence }

    factory :admin_role do
      name { 'admin' }
      slug { 'admin' }
      description { 'admin role' }
    end

    factory :executive_role do
      name { 'Executive' }
      slug { 'executive' }
      description { 'Executive role' }
    end

    factory :user_role do
      name { 'User' }
      slug { 'user' }
      description { 'User role' }
    end

  end
end
