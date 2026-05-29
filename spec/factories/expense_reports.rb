FactoryBot.define do
  factory :expense_report do
    user { nil }
    title { "MyString" }
    notes { "MyText" }
    status { 1 }
    total_amount { "9.99" }
    submitted_at { "2026-05-29 22:42:36" }
  end
end
