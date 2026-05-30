class OcrController < ApplicationController
  def create
    # 画像ファイルを受け取る
    image_file = params[:image]

    # 変換
    encoded = Base64.strict_encode64(image_file.read)

    # Google Cloud Vision APIにリクエスト
    url = "https://vision.googleapis.com/v1/images:annotate?key=#{ENV['GOOGLE_CLOUD_VISION_API_KEY']}"
    response = Faraday.post(url) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = { requests: [ { image: { content: encoded }, features: [ { type: "TEXT_DETECTION" } ] } ] }.to_json
    end

    # レスポンスからテキストを抽出
    result = JSON.parse(response.body)
    text = result.dig("responses", 0, "fullTextAnnotation", "text")

    # エラー処理
    if text.present?
      # テキストでフロントに返す
      render json: { text: text }
    else
      render json: { error: "テキストを読み取れませんでした" }, status: :unprocessable_entity
    end
  end
end
