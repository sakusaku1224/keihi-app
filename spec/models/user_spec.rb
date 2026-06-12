require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  # アソシエーション
  describe "アソシエーション" do
    it "削除すると expense_report も削除されること" do
      user = create(:user)
      create(:expense_report, user: user)
      expect { user.destroy }.to change(ExpenseReport, :count).by(-1)
    end
  end

  #  バリデーション
  describe "バリデーション" do
    # name
    context "name（名前）" do
      it "名前がなければ無効であること" do
        user.name = ""
        expect(user).not_to be_valid
        expect(user.errors[:name]).to include("入力必須")
      end
    end

    context "email（メールアドレス）" do
      it "同じメールアドレスは登録できないこと" do
        create(:user, email: "test@example.com")
        duplicate = build(:user, email: "test@example.com")
        expect(duplicate).not_to be_valid
      end
    end
  end
end
