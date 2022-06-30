FactoryBot.define do
  factory :user_profile do
    name_prefix { Faker::Name.prefix }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    name_suffix { Faker::Name.suffix }
    company { Faker::Company.name }
    title { Faker::Job.title }
    phone { Faker::PhoneNumber.phone_number }
    notes { Faker::Lorem.paragraph }
  end
end
