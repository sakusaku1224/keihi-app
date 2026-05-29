class ExpenseReport < ApplicationRecord
  belongs_to :user
  has_many :expense_items, dependent: :destroy
  # ステータス選択
  enum status: { draft: 0, submitted: 1, approved: 2 }
  # バリデーション
  validates :title, presence: true, length: { maximum: 100 }
  validates :notes, length: { maximum: 500 }
  validates :status, presence: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
