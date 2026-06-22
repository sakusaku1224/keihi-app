class Receipt < ApplicationRecord
  belongs_to :user
  belongs_to :expense_item, optional: true
  has_one_attached :receipt_image

  # スコープ
  scope :unlinked, -> { where(expense_item_id: nil) }
  scope :linked, -> { where.not(expense_item_id: nil) }

  # バリデーション
  validates :amount, numericality: { greater_than: 0, less_than_or_equal_to: 10_000_000 }, allow_nil: true
  validates :receipt_image, presence: true, content_type: %w[image/png image/jpeg application/pdf],
                            size: { less_than: 10.megabytes }
end