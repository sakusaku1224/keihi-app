FactoryBot.define do
  factory :expense_item do
    expense_report { nil }
    item_name { "MyString" }
    category { "MyString" }
    occurred_on { "2026-05-29" }
    amount { "9.99" }
    tax_rate { 1 }
    payee { "MyString" }
    invoice_registration_number { "MyString" }
    ocr_raw_text { "MyText" }
  end
end
