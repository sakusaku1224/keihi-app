require 'rails_helper'

RSpec.describe "Dashbords", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/dashbord/index"
      expect(response).to have_http_status(:success)
    end
  end

end
