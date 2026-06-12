puts "シードデータを作成中..."

# ===== ゲストユーザーの作成 =====
guest_user = User.find_or_create_by!(email: "guest@example.com") do |user|
  user.name       = "ゲストユーザー"
  user.department = "営業部"
  user.password   = SecureRandom.urlsafe_base64
end

# 冪等性：再実行しても重複しないよう既存データをリセット
guest_user.expense_reports.destroy_all

# ===== カテゴリ別の明細データ =====
ITEM_DATA = {
  "交通費"   => {
    names:     ["電車代", "タクシー代", "バス代", "新幹線代"],
    payees:    ["JR東日本", "東京メトロ", "日本交通", "東急バス"],
    amount:    (200..3_500),
    tax_rates: [10]
  },
  "食事代"   => {
    names:     ["昼食代", "会議弁当", "懇親会費", "接待夕食"],
    payees:    ["近隣レストラン", "〇〇弁当", "新橋居酒屋", "ホテル宴会場"],
    amount:    (800..6_000),
    tax_rates: [8, 10]
  },
  "宿泊費"   => {
    names:     ["ホテル宿泊費"],
    payees:    ["東横イン", "アパホテル", "ドーミーイン"],
    amount:    (7_000..12_000),
    tax_rates: [10]
  },
  "消耗品費" => {
    names:     ["文房具購入", "コピー用紙", "名刺印刷", "トナー購入"],
    payees:    ["ロフト", "アスクル", "コクヨ", "ヨドバシカメラ"],
    amount:    (300..5_000),
    tax_rates: [10]
  },
  "通信費"   => {
    names:     ["携帯電話料金", "郵便代", "宅配便"],
    payees:    ["NTTドコモ", "日本郵便", "ヤマト運輸"],
    amount:    (200..2_000),
    tax_rates: [10]
  },
  "その他"   => {
    names:     ["書籍購入", "セミナー参加費"],
    payees:    ["アマゾン", "紀伊國屋書店"],
    amount:    (500..3_000),
    tax_rates: [10]
  },
}.freeze

# ===== タイトルと明細カテゴリのセット =====
# categories: 明細に使うカテゴリ（この中からランダムで2〜3件作る）
REPORT_TYPES = [
  { title: "研修交通費",       categories: ["交通費"] },
  { title: "出張旅費",         categories: ["交通費", "宿泊費"] },
  { title: "営業先訪問交通費", categories: ["交通費"] },
  { title: "チーム懇親会費",   categories: ["食事代"] },
  { title: "消耗品購入",       categories: ["消耗品費"] },
  { title: "接待交際費",       categories: ["食事代"] },
  { title: "書籍・資料購入",   categories: ["その他"] },
  { title: "通信費",           categories: ["通信費"] },
].freeze

# ===== 申請を24件作成 =====
# approved: 12件 / submitted: 8件 / draft: 4件
# 新しい順（i=0が最新）なので、新しい方にdraft・古い方にapprovedを置く
statuses = ([:draft] * 4) + ([:submitted] * 8) + ([:approved] * 12)

statuses.each_with_index do |status, i|
  months_ago  = (i / 2) + 1
  base_date   = Date.current - months_ago.months
  report_type = REPORT_TYPES[i % REPORT_TYPES.length]
  created_at  = base_date.beginning_of_month + rand(1..15).days

  report = guest_user.expense_reports.create!(
    # 年を2桁表示（2026年→26年）
    title:        "#{base_date.strftime('%y年%-m月')} #{report_type[:title]}",
    notes:        status == :approved ? "承認済み。内容確認済みです。" : "",
    status:       status,
    submitted_at: status != :draft ? (base_date.beginning_of_month + rand(16..25).days).to_time : nil
  )

  # created_at を申請月に合わせて上書き
  report.update_columns(created_at: created_at, updated_at: created_at)

  # 明細を2〜3件作成（タイトルに合ったカテゴリから選ぶ）
  rand(2..3).times do
    category    = report_type[:categories].sample
    data        = ITEM_DATA[category]
    occurred_on = [base_date.beginning_of_month + rand(0..27), Date.current].min

    report.expense_items.create!(
      item_name:   data[:names].sample,
      category:    category,
      occurred_on: occurred_on,
      payee:       data[:payees].sample,
      amount:      rand(data[:amount]),
      tax_rate:    data[:tax_rates].sample
    )
  end
end

# ===== 結果表示 =====
puts "完了！"
puts "  申請: #{guest_user.expense_reports.count}件"
puts "    - 承認済み: #{guest_user.expense_reports.approved.count}件"
puts "    - 提出済み: #{guest_user.expense_reports.submitted.count}件"
puts "    - 下書き:   #{guest_user.expense_reports.draft.count}件"
puts "  明細: #{guest_user.expense_reports.map(&:expense_items).flatten.count}件"
