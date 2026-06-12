# field_with_errorsラッパーdivを無効化
# デフォルトではバリデーションエラー時にinputをdivでラップするが、
# Bootstrap の input-group レイアウトが崩れるため無効化する
ActionView::Base.field_error_proc = Proc.new { |html_tag, _| html_tag }
