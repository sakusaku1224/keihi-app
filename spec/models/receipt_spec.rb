require 'rails_helper'

RSpec.describe Receipt, type: :model do
  let(:item) { build(:receipt) }
  # バリデーション
  describe "バリデーション" do
    context "amount(金額)" do
      it "nilは有効" do
        item.amount = nil
        expect(item).to be_valid
      end
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
  # スコープ
  describe "スコープ" do
    it "unlinked は expense_item_id が nil のレシートを返す" do
      unlinked_receipt = create(:receipt)
      linked_receipt = create(:receipt, expense_item: create(:expense_item))

      expect(Receipt.unlinked).to include(unlinked_receipt)
      expect(Receipt.unlinked).not_to include(linked_receipt)
    end
  end
  # アソシエーション
  describe "アソシエーション" do
    it "user に属していること" do
      user = create(:user)
      item =create(:receipt, user: user)
      expect(item.user).to eq(user)
    end
  end
end
