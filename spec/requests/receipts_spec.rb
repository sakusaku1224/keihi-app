require 'rails_helper'

RSpec.describe "Receipts", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/receipts/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/receipts/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/receipts/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/receipts/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
