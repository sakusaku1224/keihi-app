FactoryBot.define do
  factory :expense_item do
    association :expense_report
    item_name    { "タクシー代" }
    category     { "交通費" }
    occurred_on  { Date.yesterday }   # 今日より前の日付（バリデーションを通すため）
    amount       { 1000 }
    tax_rate     { 10 }
    payee        { "〇〇タクシー" }
    invoice_registration_number { "" } # 任意項目なので空でOK
  end
end
