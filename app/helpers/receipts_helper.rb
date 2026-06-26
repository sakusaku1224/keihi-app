module ReceiptsHelper
  CATEGORY_COLORS = {
    "交通費" => "#F59E0B",
    "食事代" => "#06B6D4",
    "宿泊費" => "#6366F1",
    "消耗品費" => "#d8a",
    "通信費" => "#8b5",
    "その他" => "#9ca3af",
  }.freeze

  def category_dot(category)
    color = CATEGORY_COLORS[category] || "#9ca3af"
    tag.span("", style: "display:inline-block; width:9px; height:9px; border-radius:3px; background:#{color}; margin-right:6px;")
  end
end
