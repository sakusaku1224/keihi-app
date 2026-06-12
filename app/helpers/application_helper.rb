module ApplicationHelper
  # フォームエラー文
  def error_message(object, field)
    if object.errors[field].any?
      content_tag(:div, object.errors[field].first,
                  class: "invalid-feedback d-block")
    end
  end
end
