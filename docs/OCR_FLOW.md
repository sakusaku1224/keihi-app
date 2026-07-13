# OCR処理　フローの復習

AI活用しながら実装したため、再度処理の流れを自分で理解するために復習する。

## 使用した技術

### gem・API

| gem / API | 用途 |
|---|---|
| **Claude API（claude-haiku-4-5）** | 領収書の読み取り・項目の分類 |
| **dotenv-rails** | APIキーを環境変数で管理 |

### JSライブラリ

| ライブラリ | 用途 |
|---|---|
| **browser-image-compression** | API送信前に画像を圧縮（1.5MB・1600px以下） |

## 概要：

入口は「明細モーダルでOCRボタンを押す」「レシートBOXに追加」の２パターン、成型担当のReceiptScanner・通信担当OcrServiceの２つの共通ロジックを使用している。レシートBOXを後から実装したため、既存のコードを再利用するためにサービス部分を切り出した。

## レシートBOX側でもでOCRを実装した理由

当初は画像だけもたせ、既存のサービスに統合することも検討したが、"未回収金額を可視化して行動を促す"というアプリの中核価値を実現するには、金額を集計可能な形で持つ必要があったから。

## 全体像：
<img width="629" height="665" alt="スクリーンショット 2026-07-13 20 40 05" src="https://github.com/user-attachments/assets/6ed023ea-fded-4a63-a6de-1f5853ee65ac" />


## 明細モーダルでOCRボタンを押し、表示されるまでの流れ

### 1:画像をアップロードし、OCRボタンを押す

　app/javascript/application.js L95〜105

      // ファイルをドロップまたは選択したとき currentFile にセット
      receiptFileInput.addEventListener("change", (event) => {
        currentFile = event.target.files[0];
        showPreview(currentFile);
      });

      // browser-image-compression ライブラリで圧縮（1.5MB・1600px以下に）
      if (typeof imageCompression !== "undefined") {
        fileToSend = await imageCompression(currentFile, options);
      }

    （なぜブラウザ側で圧縮？：
      通信量を減らすため。APIの無料プランの非力なインスタンスに対応。
      サイズ上限の担保はサーバー側のバリデーション（10MB未満）で行っている）

### 2:サーバーへ送信（Fetch API）

    app/javascript/application.js L140〜151

      const formData = new FormData();
      formData.append("receipt_image", fileToSend);

      fetch("/ocr", {          // POST /ocr → ocr#create
        method: "POST",
        body: formData,
        headers: { "X-CSRF-Token": ... }
      })
      (fetch：画面を移動せずに、データだけをやり取りできる)

      ルーティング：config/routes.rb L28
        resources :ocr, only: %i[create]
        # POST /ocr → OcrController#create

### ３：コントローラがサービスを呼ぶ

app/controllers/ocr_controller.rb L4〜12

    image_file = params[:receipt_image]   # フォームから受け取り
    data = ReceiptScanner.new(image_file).call  # サービス層へ委譲

### 4:ReceiptScanner がOcrService を呼び出す

    app/services/receipt_scanner.rb L1~

      def call
        result = OcrService.new(@image_file).call  # API通信を委託
      end

### 5: OcrServiceがClaude API に画像を送る

app/services/ocr_service.rb L13〜68

      # Base64に変換
      image_data = Base64.strict_encode64(File.read(@image_file.path))

      # PDFか画像かで送り方を分岐（L19〜37）
      media_content = if content_type == "application/pdf"
        { type: "document", source: { type: "base64", ... } }
      else
        { type: "image",    source: { type: "base64", ... } }
      end

      # Claude API（claude-haiku-4-5）に送信（L40〜68）
      uri = URI("https://api.anthropic.com/v1/messages")
      request.body = JSON.generate({
        model: "claude-haiku-4-5",
        messages: [{ role: "user", content: [media_content, { type: "text", text: prompt }] }]
      })
      response = http.request(request)
      JSON.parse(response.body)

### 6: ReceiptScannerがレスポンスを成型

    app/services/receipt_scanner.rb L1〜26

    def call
      text = result.dig("content", 0, "text")   # レスポンスからテキスト抽出

      # ```json ... ``` の記法を除去してパース
      text = text.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip
      data = JSON.parse(text)
    end

### 7: ocr_controllerでdataをjsonで返す

    render json: data                          # JSONで返す

### 8: フォームに自動入力

    app/javascript/application.js L153〜160（runOcr() のコールバック）

    .then((data) => {
      fillFormFromOcr(data)   // フォームに流し込む
    })

### まとめ

    ocr_controller
    └→ ReceiptScanner を呼ぶ
      └→ OcrService を呼ぶ
        └→ Claude API と通信
        └→ 生レスポンスを返す
      └→ JSONに整形して返す
    └→ render json: data
    app/javascript/application.js
    └→ fillFormFromOcr(data) でフォームに流す

## 明細モーダルでOCRボタンを押し、表示されるまでの流れ

### 1:レシートBOXにアップロードし、保存ボタンを押す

app/views/receipts/new.html.erb L5〜22

    <%= form_with model: @receipt do |f| %>
      <%= f.file_field :receipt_image, id: "receipt-file-input" %>
      <%= f.submit "保存" %>  ← 押したらそのままPOST送信
    <% end %>
    「撮ってすぐ保存」を想定しているので、JSなしでサーバー側でOCRまで完結する

### 2: コントローラがReceiptScanner呼び出し

app/controllers/receipts_controller.rb L12〜38

    def create
      @receipt = current_user.receipts.build(receipt_params)
      image = params[:receipt][:receipt_image]

      if image.present?　# 画像必須なのでガード
        data = ReceiptScanner.new(image).call   # ← 入口①と同じサービス層
      end
    end

### 3: OCR処理実行

ReceiptScanner → OcrService → Claude API → 整形 → dataに格納

### 4: 結果をDBに保存

    def create
      if image.present?
        data = ReceiptScanner.new(image).call # サービス層でOCR実行
        if data.present?
          @receipt.assign_attributes( # OCR結果をレコードに反映
          amount: data["amount"],
          occurred_on: data["occurred_on"],
          payee: data["payee"],
          category: data["category"],
          invoice_registration_number: data["invoice_registration_number"]
          )
      end
    end

if @receipt.save # DBに保存（expense_item_id: NULLのまま）
redirect_to receipts_path
end
end
(まだ明細に紐づいていないので、この時点では expense_item_id: NULLのまま)

### 5: DBに保存された状態

id: 3
user_id: 1
amount: 760
payee: "九州旅客鉄道株式会社"
occurred_on: "2025-06-06"
expense_item_id: NULL ← まだ明細に紐付いていない
receipt_image: (Active Storageで保存)

app/models/receipt.rb L7
scope :unlinked, -> { where(expense_item_id: nil) } # NULL = BOX内

### 6: 明細フォームのドロップダウンに表示

app/controllers/expense_reports_controller.rb L41

def show
@unlinked_receipts = current_user.receipts.unlinked # BOX内のレシートを取得
end

app/views/expense_items/\_form.html.erb L24〜50

    <% @unlinked_receipts.each do |receipt| %>
      <li>
        <a href="#" onclick="
          fetch('/receipts/<%= receipt.id %>.json')  ← JSONで呼び出し
            .then(r => r.json())
            .then(d => {
              fillFormFromOcr(d)   ← 入口①と同じ関数でフォームに流す
              document.getElementById('selected_receipt_id').value = d.id;
            })">
          <%= receipt.payee %> ¥<%= receipt.amount %>
        </a>
      </li>
    <% end %>

### 7: 選択するとreceipts#show がJSONを返す

app/controllers/receipts_controller.rb L41〜50

    def show
      render json: {
        id:                          @receipt.id,
        amount:                      @receipt.amount,
        payee:                       @receipt.payee,
        occurred_on:                 @receipt.occurred_on,
        category:                    @receipt.category,
        invoice_registration_number: @receipt.invoice_registration_number,
        image_url:                   url_for(@receipt.receipt_image)
      }
    end

### 8: フォームに流す

app/views/expense_items/\_form.html.erb L24〜50

    <% @unlinked_receipts.each do |receipt| %>
      <li>
        <a href="#" onclick="
            .then(d => {
              fillFormFromOcr(d)   ← 入口①と同じ関数でフォームに流す
              document.getElementById('selected_receipt_id').value = d.id;
            })">
          <%= receipt.payee %> ¥<%= receipt.amount %>
        </a>
      </li>
    <% end %>

app/javascript/application.js L181〜212

    function fillFormFromOcr(data) {
      // DBに保存されていたOCRデータをフォームに流し込む
      document.getElementById("expense_item_item_name").value = data.item_name;
      document.getElementById("expense_item_category").value  = data.category;
      document.getElementById("expense_item_amount").value    = Math.round(data.amount);
      document.getElementById("expense_item_payee").value     = data.payee;
      fpInstance.setDate(data.occurred_on, true);
    }

### 9: 保存ボタンでhidden fieldにセットされた receipt_id が一緒に送信

app/views/expense_items/\_form.html.erb L23

    <input type="hidden" id="selected_receipt_id" name="receipt_id" value="">

### 10: 明細紐付け

app/controllers/expense_items_controller.rb L14〜19

    def create
      @expense_item = @expense_report.expense_items.build(expense_item_params)
      if @expense_item.save
        if params[:receipt_id].present?
          receipt = current_user.receipts.find(params[:receipt_id])  # ユーザースコープで安全に取得
          receipt.update(expense_item_id: @expense_item.id)          # NULLだったIDを更新
        end
      end
    end

    明細を保存できたら
    receipt_id が送られてきていたら
    ログイン中のユーザーのレシートの中から
    そのreceipt_idのレシートを取得して
    そのレシートのexpense_item_idを
    今保存したばかりの明細のIDで更新する

### 11: レシートBOXのレシートが明細と紐付き、BOXから消える

scope :unlinked から外れ、BOXから消えます。

### まとめ

new.html.erb でファイル選択・保存ボタン押す（JSなし）
↓
receipts#create → ReceiptScanner → OcrService → Claude API
↓
OCR結果 + 画像をDBに保存（expense_item_id: NULL）
↓
明細フォームのドロップダウンに表示（unlinked スコープ）
↓
選択 → fetch('/receipts/:id.json') → fillFormFromOcr() でフォームに入力
↓
保存 → receipt.update(expense_item_id: @expense_item.id) で紐付け完了
