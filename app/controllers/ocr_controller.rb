class OcrController < ApplicationController
  def create
    # ① 画像を受け取る
    image_file = params[:receipt_image]

    # ② 画像がなければエラー
    if image_file.blank?
      render json: { error: "画像がありません" }, status: :bad_request and return
    end

    # ③ OcrService で Claude API を呼ぶ
    result = OcrService.new(image_file).call

    # ④ API がエラーを返した場合（{"type":"error",...}）はログを出してエラーを返す
    if result["type"] == "error"
      error_msg = result.dig("error", "message") || "API エラー"
      Rails.logger.error "OCR API Error: #{error_msg}"
      render json: { error: "OCR の読み取りに失敗しました" }, status: :unprocessable_entity and return
    end

    # ⑤ Claude のレスポンスから JSON 部分を取り出す
    text = result.dig("content", 0, "text")

    if text.nil?
      Rails.logger.error "OCR Error: response text is nil. Full result: #{result.inspect}"
      render json: { error: "OCR の読み取りに失敗しました" }, status: :unprocessable_entity and return
    end

    # マークダウンのコードブロック（```json ... ```）が含まれる場合は除去
    text = text.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
    data = JSON.parse(text)

    # ⑥ 結果を返す
    render json: data

  rescue JSON::ParserError => e
    Rails.logger.error "OCR JSON Parse Error: #{e.message}"
    render json: { error: "OCR の読み取りに失敗しました" }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "OCR Unexpected Error: #{e.class} - #{e.message}"
    render json: { error: "OCR の読み取りに失敗しました" }, status: :unprocessable_entity
  end
end
