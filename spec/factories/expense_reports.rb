FactoryBot.define do
  factory :expense_report do
    association :user           # Userと紐づける
    title  { "2026年6月 交通費申請" }
    notes  { "6月分の交通費まとめ" }
    status { :draft }           # enumのシンボルで指定
    total_amount { 0 }

    # trait: 特定の状態のデータを簡単に作れる
    trait :submitted do
      status { :submitted }
      submitted_at { Time.current }
    end

    trait :approved do
      status { :approved }
      submitted_at { 1.day.ago }
    end
  end
end
