class ExpenseItem < ApplicationRecord
  belongs_to :expense_report
  has_one_attached :receipt_image

  CATEGORIES = %w[ 交通費 食事代 宿泊費 消耗品費 通信費 その他 ].freeze
  TAX_RATES = [ 0, 8, 10 ].freeze

  # バリデーション
  validates :item_name, presence: true, length: { maximum: 50 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :occurred_on, presence: true
  validate :occurred_on_cannot_be_future
  validates :amount, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 10_000_000 }
  validates :tax_rate, presence: true, inclusion: { in: TAX_RATES }
  validates :invoice_registration_number, format: { with: /\AT\d{13}\z/ }, allow_blank: true
  validates :payee, presence: true, length: { maximum: 50 }
  validates :receipt_image, content_type: %w[image/png image/jpeg application/pdf],
                            size: { less_than: 10.megabytes }

  # 明細が保存・削除されたら合計を更新
  after_save    :update_report_total
  after_destroy :update_report_total

  private
  # 未来NG
  def occurred_on_cannot_be_future
    return if occurred_on.blank?
    if occurred_on > Date.current
      errors.add(:occurred_on, "今日以前の日付を選択してください")
    end
  end

  # 合計値算出
  def update_report_total
    expense_report.update_column(
      :total_amount, expense_report.expense_items.sum(:amount)
    )
  end
end
