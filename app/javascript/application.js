// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

// 明細詳細画面トグル
function toggleRow(id) {
  const detailRow = document.getElementById("detail-" + id);
  const icon = document.getElementById("icon-" + id);

  if (!detailRow) {
    return;
  }

  const isHidden = detailRow.classList.contains("d-none");
  // 非表示の場合
  if (isHidden) {
    detailRow.classList.remove("d-none");
    // アイコンを回転させる
    icon.classList.add("rotated");
  }
  // 表示中の場合
  else {
    detailRow.classList.add("d-none");
    icon.classList.remove("rotated");
  }
}
window.toggleRow = toggleRow;

// 明細追加画面
function initReceiptUpload() {
  // 要素取得
  const uploadZone = document.getElementById("upload-zone");
  const previewCard = document.getElementById("preview-card");
  const previewImg = document.getElementById("preview-img");
  const receiptFileInput = document.getElementById("receipt-file-input");
  const clearPreviewBtn = document.getElementById("clear-preview-btn");
  let currentFile = null;

  // 画像アップロード時
  function showPreview(file) {
    const isPdf = file.type === "application/pdf";

    if (isPdf) {
      // PDF の場合：ブラウザのネイティブ表示を使う
      const pdfPreview = document.getElementById("pdf-preview");
      pdfPreview.src = URL.createObjectURL(file);
      pdfPreview.classList.remove("d-none");
      previewImg.classList.add("d-none");
      uploadZone.classList.add("d-none");
      previewCard.classList.remove("d-none");
      document.getElementById("ocr-btn").classList.remove("d-none");
    } else {
      // 画像の場合：FileReader で DataURL に変換してプレビュー表示
      const reader = new FileReader();
      reader.onload = function () {
        previewImg.src = reader.result;
        previewImg.classList.remove("d-none");
        document.getElementById("pdf-preview").classList.add("d-none");
        uploadZone.classList.add("d-none");
        previewCard.classList.remove("d-none");
        document.getElementById("ocr-btn").classList.remove("d-none");
      };
      reader.readAsDataURL(file);
    }
  }

  // 画像削除・初期状態に戻す
  function clearPreview() {
    previewCard.classList.add("d-none");
    uploadZone.classList.remove("d-none");
    // ファイルinputをリセット
    receiptFileInput.value = "";
    currentFile = null;
    document.getElementById("ocr-btn").classList.add("d-none");
    // PDF / 画像の表示状態をリセット
    previewImg.classList.remove("d-none");
    const pdfPreview = document.getElementById("pdf-preview");
    URL.revokeObjectURL(pdfPreview.src); // メモリ解放
    pdfPreview.src = "";
    pdfPreview.classList.add("d-none");
  }

  // イベントリスナー
  if (!uploadZone) return;
  // クリックされたら、ファイルフィールドを発火
  uploadZone.addEventListener("click", () => {
    receiptFileInput.click();
  });

  // ドラッグ中にデフォルト動作をキャンセル
  uploadZone.addEventListener("dragover", (event) => {
    event.preventDefault();
  });

  // ドロップされたとき
  uploadZone.addEventListener("drop", (event) => {
    event.preventDefault();
    currentFile = event.dataTransfer.files[0];
    showPreview(currentFile);
  });

  // ファイルを選択したとき
  receiptFileInput.addEventListener("change", (event) => {
    currentFile = event.target.files[0];
    showPreview(currentFile);
  });

  // × ボタンを押したとき初期化
  clearPreviewBtn.addEventListener("click", () => {
    clearPreview();
  });

  // OCR ボタンを押したとき
  document.getElementById("ocr-btn").addEventListener("click", () => {
    runOcr();
  });

  // OCR 読み取り実行
  function runOcr() {
    // ファイルがなければ何もしない
    if (!currentFile) return;

    // スピナー
    const ocrBtn = document.getElementById("ocr-btn");
    ocrBtn.disabled = true;
    ocrBtn.innerHTML =
      '<span class="spinner-border spinner-border-sm"></span> 読み取り中...';

    // FormData を作ってファイルを追加
    const formData = new FormData();
    formData.append("receipt_image", currentFile);

    // サーバーに送る
    fetch("/ocr", {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
      },
    })
      .then((res) => res.json())
      .then((data) => {
        ocrBtn.disabled = false;
        ocrBtn.innerHTML = '<i class="bi bi-magic"></i> OCR 読み取り';
        if (data.error) {
          alert("OCR の読み取りに失敗しました: " + data.error);
          return;
        }
        fillFormFromOcr(data);
      })
      .catch(() => {
        ocrBtn.disabled = false;
        ocrBtn.innerHTML = '<i class="bi bi-magic"></i> OCR 読み取り';
        alert("OCR の読み取りに失敗しました");
      });
  }

}

// フォームに自動入力（OCR・レシートBOX共用）
function fillFormFromOcr(data) {
  if (data.item_name) document.getElementById("expense_item_item_name").value = data.item_name;
  if (data.category) document.getElementById("expense_item_category").value = data.category;
  const fpInstance = document.getElementById(
    "expense_item_occurred_on",
  )?._flatpickr;
  if (fpInstance && data.occurred_on) {
    fpInstance.setDate(data.occurred_on, true);
  } else if (data.occurred_on) {
    document.getElementById("expense_item_occurred_on").value = data.occurred_on;
  }
  if (data.amount) document.getElementById("expense_item_amount").value = Math.round(data.amount);
  if (data.payee) document.getElementById("expense_item_payee").value = data.payee;
  if (data.invoice_registration_number) {
    document.getElementById("expense_item_invoice_registration_number").value = data.invoice_registration_number;
  }
  const taxRadio = document.querySelector(
    `input[name="expense_item[tax_rate]"][value="${data.tax_rate}"]`,
  );
  if (taxRadio) taxRadio.checked = true;
}
window.fillFormFromOcr = fillFormFromOcr;

// 画像プレビュー（PDFは別タブで開くのでここでは画像のみ対象）
function initImagePreview() {
  document.querySelectorAll(".receipt-preview-img").forEach((img) => {
    img.addEventListener("click", () => {
      document.getElementById("modal-preview-img").src = img.src;
      const modal = new bootstrap.Modal(
        document.getElementById("imagePreviewModal"),
      );
      modal.show();
    });
  });
}

// カレンダー初期化
function initFlatpickr() {
  flatpickr("input[type='date']", {
    locale: "ja",
    dateFormat: "Y-m-d",
    altInput: true,
    altFormat: "Y/m/d", //　表示用
    allowInput: true,
    // 日付が選択・変更されたら、隠れている元のinputから is-invalid を外す
    onChange: (selectedDates, dateStr, instance) => {
      instance.input.classList.remove("is-invalid");
      if (instance.altInput) {
        instance.altInput.classList.remove("is-invalid");
      }
    },
  });
}

// エラー表示の解除
function initValidationClear() {
  document.querySelectorAll(".is-invalid").forEach((field) => {
    field.addEventListener("input", () => {
      field.classList.remove("is-invalid");

      // エラーメッセージ消す（親要素を探す）
      const parent = field.closest(".col-12, .col-6, .mb-4, .mb-3");
      const feedback = parent?.querySelector(".invalid-feedback");
      if (feedback) feedback.remove();
    });
  });
}

// グラフ
function initCharts() {
  const el = document.getElementById("chart-data");
  // ダッシュボードのみ
  if (!el) return;

  // JSONを配列に
  const labels = JSON.parse(el.dataset.labels);
  const values = JSON.parse(el.dataset.values);
  // 文字列を数値に
  const draft = parseInt(el.dataset.draft);
  const submitted = parseInt(el.dataset.submitted);
  const approved = parseInt(el.dataset.approved);

  // 棒グラフ
  new Chart(document.getElementById("monthlyChart"), {
    type: "bar",
    data: {
      labels,
      datasets: [
        {
          data: values,
          // 今月だけ濃い緑
          backgroundColor: values.map((_, i) =>
            i === values.length - 1 ? "#639b8c" : "#e1e3e0",
          ),
          borderRadius: 4,
          barPercentage: 0.5,
        },
      ],
    },
    options: {
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        y: { display: false },
        x: { grid: { display: false } },
      },
    },
  });

  // ステータス分布ドーナツグラフ
  new Chart(document.getElementById("statusChart"), {
    type: "doughnut",
    data: {
      labels: ["下書き", "提出済み", "承認済み"],
      datasets: [
        {
          data: [draft, submitted, approved],
          backgroundColor: ["#faecb6", "#c8d9f1", "#bddbce"],
          borderWidth: 1,
        },
      ],
    },
    options: {
      maintainAspectRatio: false,
      cutout: "60%",
      radius: "80%",
      plugins: {
        legend: { position: "right", labels: { font: { size: 11 } } },
      },
    },
  });
}
// ページが読み込まれるたびに初期化
document.addEventListener("turbo:load", () => {
  initReceiptUpload();
  initImagePreview();
  initFlatpickr();
  initValidationClear();
  initCharts();
});

// バリデーションエラーはturbo:loadが発火しないためturbo:renderで補完
document.addEventListener("turbo:render", () => {
  initValidationClear();
});

// Turbo Streamで部分更新されたときも、初期化
document.addEventListener("turbo:before-stream-render", (event) => {
  const original = event.detail.render;
  event.detail.render = (streamElement) => {
    original(streamElement);
    initReceiptUpload();
    initImagePreview();
    initFlatpickr();
    initValidationClear();
  };
});
