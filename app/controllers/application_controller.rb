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
end
