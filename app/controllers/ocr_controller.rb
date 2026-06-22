class OcrController < ApplicationController
  def create
    # 画像を受け取る
    image_file = params[:receipt_image]

    # 画像がなければエラー
    if image_file.blank?
      render json: { error: "画像がありません" }, status: :bad_request and return
    end

    # 呼び出し
    data = ReceiptScanner.new(image_file).call

    # エラーを返す
    if data.nil?
      render json: { error: "読み取りに失敗しました" }, status: :unprocessable_entity and return
    end

    # 結果を返す
    render json: data

  rescue JSON::ParserError => e
    Rails.logger.error "OCR JSON Parse Error: #{e.message}"
    render json: { error: "読み取りに失敗しました" }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "OCR Unexpected Error: #{e.class} - #{e.message}"
    render json: { error: "読み取りに失敗しました" }, status: :unprocessable_entity
  end
end
