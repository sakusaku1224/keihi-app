class Users::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, only: [:guest_sign_in]

  def guest_sign_in
    guest_user = User.find_or_create_by!(email: "guest@example.com") do |user|
      user.name       = "ゲストユーザー"
      user.department = "デモ部署"
      user.password   = SecureRandom.urlsafe_base64
    end
    sign_in guest_user
    redirect_to root_path, notice: "ゲストとしてログインしました"
  end
end
