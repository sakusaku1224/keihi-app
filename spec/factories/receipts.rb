FactoryBot.define do
  factory :receipt do
    association :user
    category     { "交通費" }
    occurred_on  { Date.yesterday }
    amount       { 1000 }
    payee        { "〇〇タクシー" }
    invoice_registration_number { "T123456789123１" }
  end
end