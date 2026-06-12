class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  # 登録とプロフ更新時に名前と部署を追加する
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[ name department ])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[ name department ])
  end

  # ログアウト後はルートを経由せず直接ログイン画面へ
  # （ルート→authenticate_user!→ログイン画面 の経由でflash[:notice]が消えるのを防ぐ）
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
