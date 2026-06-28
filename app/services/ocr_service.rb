require "net/http"
require "base64"
require "json"
require "uri"

class OcrService
  # 初期化（画像ファイルを受け取る）
  def initialize(image_file)
    @image_file = image_file
  end

  # Claude API を呼んで OCR 結果を返す
  def call
    # ファイルを Base64 に変換
    image_data   = Base64.strict_encode64(File.read(@image_file.path))
    content_type = @image_file.content_type

    # PDFか画像かで送り方を変える
    media_content = if content_type == "application/pdf"
      {
        type:   "document",
        source: {
          type:       "base64",
          media_type: "application/pdf",
          data:       image_data
        }
      }
    else
      {
        type:   "image",
        source: {
          type:       "base64",
          media_type: content_type,
          data:       image_data
        }
      }
    end

    # リクエスト先
    uri  = URI("https://api.anthropic.com/v1/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    # リクエスト組み立て
    request = Net::HTTP::Post.new(uri)
    request["x-api-key"]         = api_key
    request["anthropic-version"] = "2023-06-01"
    request["content-type"]      = "application/json"
    request.body = JSON.generate({
      model:      "claude-haiku-4-5",
      max_tokens: 1024,
      messages: [
        {
          role:    "user",
          content: [
            media_content,
            {
              type: "text",
              text: prompt
            }
          ]
        }
      ]
    })

    # API 呼び出し・レスポンスを返す
    response = http.request(request)
    JSON.parse(response.body)
  end

  private

  def api_key
    ENV["ANTHROPIC_API_KEY"]
  end

  def prompt
    <<~PROMPT
      この領収書・レシートの画像から以下の項目を読み取り、JSONのみ返してください。
      他の文章は一切不要です。

      {
        "category": "交通費, 食事代, 宿泊費, 消耗品費, 通信費, その他 のいずれか",
        "occurred_on": "YYYY-MM-DD形式",
        "amount": 数値のみ（円マーク・カンマ不要。税込金額を優先）,
        "tax_rate": 数値のみ（0・8・10 のいずれか。複数税率がある場合は主要な方）,
        "payee": "発行元の正式な会社名・法人名（例：東日本旅客鉄道株式会社）。略称やブランド名ではなく、領収書に記載された正式名称を使用すること。見つからない場合は店舗名",
        "invoice_registration_number": "Tで始まり、その後は13桁の半角数字。なければ空文字"
      }
    PROMPT
  end
end
