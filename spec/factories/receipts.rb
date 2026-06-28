FactoryBot.define do
  factory :receipt do
    association :user
    category     { "交通費" }
    occurred_on  { Date.yesterday }
    amount       { 1000 }
    payee        { "関東鉄道" }
    invoice_registration_number { "T1234567891231" }
    receipt_image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/test_receipt.jpg"), "image/jpeg") }
  end
end