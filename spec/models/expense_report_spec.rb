require 'rails_helper'
RSpec.describe ExpenseReport, type: :model do
  let(:report) { build(:expense_report) }

  # アソシエーション
  describe "アソシエーション" do
    it "user に属していること" do
      user = create(:user)
      report =create(:expense_report, user: user)
      expect(report.user).to eq(user)
    end

    it "expense_items を持てること" do
      report = create(:expense_report)
      item = create(:expense_item, expense_report: report)
      expect(report.expense_items).to include(item)
    end

    it "削除すると expense_items も削除されること" do
      report = create(:expense_report)
      create(:expense_item, expense_report: report)
      expect { report.destroy }.to change(ExpenseItem, :count).by(-1)
    end
  end

  # バリデーション
  describe "バリデーション" do
    context "title (申請タイトル)" do
      it "空なら無効であること" do
        report.title = ""
        expect(report).not_to be_valid
      end
      it "101文字以上なら無効" do
        report.title = "あ" * 101
        expect(report).not_to be_valid
      end
    end
    context "total_amount (合計金額)" do
      it "0なら有効" do
        report.total_amount = 0
        expect(report).to be_valid
      end
      it "マイナスなら無効" do
        report.total_amount = -1
        expect(report).not_to be_valid
      end
      it "nilは有効" do
        report.total_amount = nil
        expect(report).to be_valid
      end
    end
  end

  # ステータス
  describe "ステータス(enum)" do
    it "デフォルトステータスは draft であること" do
      expect(report).to be_draft
    end
    it "submitted に変更すると submitted? がtrueになる" do
      report.status = :submitted
      expect(report).to be_submitted
    end
    it "approved な申請は approved? がtrueになる" do
      approved_report = build(:expense_report, :approved)
      expect(approved_report).to be_approved
    end
  end
end
