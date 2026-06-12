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

    # ④ Claude のレスポンスから JSON 部分を取り出す
    text = result.dig("content", 0, "text")
    # マークダウンのコードブロック（```json ... ```）が含まれる場合は除去
    text = text.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
    data = JSON.parse(text)

    # ⑤ 結果を返す
    render json: data

  rescue JSON::ParserError
    render json: { error: "OCR の読み取りに失敗しました" }, status: :unprocessable_entity
  end
end
