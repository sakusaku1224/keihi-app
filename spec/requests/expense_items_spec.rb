require 'rails_helper'

RSpec.describe "ExpenseItems", type: :request do
  let(:user) { create(:user) }
  before { sign_in user }
  describe "POST /expense_reports/:id/expense_items" do
    it "receipt_idを渡すと、レシートが紐づく" do
      expense_report = create(:expense_report, user: user)
      receipt = create(:receipt, user: user)
      # 実行リクエストの際に、receipt_idも送る
      post expense_report_expense_items_path(expense_report), params: {
        expense_item: attributes_for(:expense_item),
        receipt_id: receipt.id
      }
      receipt.reload
      expect(receipt.expense_item_id).to be_present
    end
  end
end
