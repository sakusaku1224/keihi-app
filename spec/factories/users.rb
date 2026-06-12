FactoryBot.define do
  factory :user do
    name       { Faker::Name.name }
    department { Faker::Company.department }
    email      { Faker::Internet.unique.email }
    password   { "password123" }
  end
end
