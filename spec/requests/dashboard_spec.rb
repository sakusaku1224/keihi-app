# spec/requests/dashboard_spec.rb
require 'rails_helper'
RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user) }
  it "未ログインならログイン画面へリダイレクト" do
    get root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "ログイン済みなら表示される" do
    sign_in user
    get root_path
    expect(response).to have_http_status(:success)
  end
end
