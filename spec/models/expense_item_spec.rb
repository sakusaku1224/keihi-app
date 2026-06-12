require 'rails_helper'

RSpec.describe ExpenseItem, type: :model do
  let(:item) { build(:expense_item) }
  # バリデーション
  describe "バリデーション" do
    context "occurred_on (発生日)" do
      it "未来の日付なら無効" do
        item.occurred_on = Date.tomorrow
        expect(item).not_to be_valid
        expect(item.errors[:occurred_on]).to include("今日以前の日付を選択してください")
      end
      it "今日の日付なら有効" do
        item.occurred_on = Date.current
        expect(item).to be_valid
      end
      it "昨日の日付なら有効" do
        item.occurred_on = Date.yesterday
        expect(item).to be_valid
      end
    end
    context "amount(金額)" do
      it "0円は無効" do
        item.amount = 0
        expect(item).not_to be_valid
      end
      it "10000000円以内は有効" do
        item.amount = 10000000
        expect(item).to be_valid
      end
      it "10000001円以上は無効" do
        item.amount = 10000001
        expect(item).not_to be_valid
      end
    end
  end
  # 金額の自動更新
  describe "コールバック" do
    it "明細を保存すると合計金額が更新される" do
      report = create(:expense_report)
      create(:expense_item, expense_report: report, amount: 1000)
      create(:expense_item, expense_report: report, amount: 2000)
      expect(report.reload.total_amount).to eq(3000)
    end
  end
end
