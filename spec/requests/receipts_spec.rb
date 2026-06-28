require 'rails_helper'

RSpec.describe "Receipts", type: :request do
  let(:user) { create(:user) }
  before { sign_in user }

  describe "GET /receipts" do
    it "一覧が表示される" do
      get receipts_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /receipts/:id" do
    it "JSONが返る" do
      receipt = create(:receipt, user: user)
      get receipt_path(receipt)
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /receipts/:id" do
    it "削除できる" do
      receipt = create(:receipt, user: user)
      expect { delete receipt_path(receipt) }.to change(Receipt, :count).by(-1)
    end
    it "明細に使用したレシートは削除できない" do
      receipt = create(:receipt, user: user, expense_item: create(:expense_item))
      expect { delete receipt_path(receipt) }.to change(Receipt, :count).by(0)
      expect(response).to redirect_to(receipts_path)
    end
  end
end
