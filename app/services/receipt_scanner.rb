class ReceiptScanner
  def initialize(image_file)
    @image_file = image_file
  end

  def call
    # 呼び出し
    result = OcrService.new(@image_file).call

    # エラー判定
    if result["type"] == "error"
      Rails.logger.error "OCR API Error: #{result.dig("error", "message")}"
      return nil
    else
      # テキスト切り出し
      text = result.dig("content", 0, "text")
      if text.nil?
        return nil
      end

      # json変換
      text = text.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
      data = JSON.parse(text)
    end
  end
end
