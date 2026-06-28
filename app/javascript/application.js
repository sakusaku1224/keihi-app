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
  async function runOcr() {
    // ファイルがなければ何もしない
    if (!currentFile) return;

    // スピナー
    const ocrBtn = document.getElementById("ocr-btn");
    ocrBtn.disabled = true;
    ocrBtn.innerHTML =
      '<span class="spinner-border spinner-border-sm"></span> 読み取り中...';

    // 画像を圧縮（ライブラリが読み込まれていれば）
    let fileToSend = currentFile;
    if (typeof imageCompression !== "undefined") {
      const options = {
        maxSizeMB: 1.5,
        maxWidthOrHeight: 1600,
        useWebWorker: true,
      };
      fileToSend = await imageCompression(currentFile, options);
    }

    // FormData を作ってファイルを追加
    const formData = new FormData();
    formData.append("receipt_image", fileToSend);

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
      .catch((err) => {
        console.error("OCR Error:", err);
        ocrBtn.disabled = false;
        ocrBtn.innerHTML = '<i class="bi bi-magic"></i> OCR 読み取り';
        alert("OCR の読み取りに失敗しました");
      });
  }
}

// バリデーションエラー表示をクリア
function clearValidationErrors(form) {
  if (!form) return;
  form
    .querySelectorAll(".is-invalid")
    .forEach((el) => el.classList.remove("is-invalid"));
  form.querySelectorAll(".invalid-feedback").forEach((el) => el.remove());
}

// フォームに自動入力（OCR・レシートBOX共用）
function fillFormFromOcr(data) {
  const form = document.getElementById("new_item_form");
  clearValidationErrors(form);

  if (data.item_name)
    document.getElementById("expense_item_item_name").value = data.item_name;
  if (data.category)
    document.getElementById("expense_item_category").value = data.category;
  const fpInstance = document.getElementById(
    "expense_item_occurred_on",
  )?._flatpickr;
  if (fpInstance && data.occurred_on) {
    fpInstance.setDate(data.occurred_on, true);
  } else if (data.occurred_on) {
    document.getElementById("expense_item_occurred_on").value =
      data.occurred_on;
  }
  if (data.amount)
    document.getElementById("expense_item_amount").value = Math.round(
      data.amount,
    );
  if (data.payee)
    document.getElementById("expense_item_payee").value = data.payee;
  if (data.invoice_registration_number) {
    document.getElementById("expense_item_invoice_registration_number").value =
      data.invoice_registration_number;
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
  if (!el) return;
  if (typeof Chart === "undefined") return;

  const canvas = document.getElementById("monthlyChart");
  if (!canvas) return;

  const existing = Chart.getChart(canvas);
  if (existing) existing.destroy();

  const labels = JSON.parse(el.dataset.labels);
  const values = JSON.parse(el.dataset.values);
  const draft = parseInt(el.dataset.draft);
  const submitted = parseInt(el.dataset.submitted);
  const approved = parseInt(el.dataset.approved);

  new Chart(canvas, {
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
      plugins: {
        legend: { display: false },
        tooltip: {
          titleFont: { size: 18 },
          bodyFont: { size: 20 },
        },
      },
      scales: {
        y: { display: false },
        x: { grid: { display: false } },
      },
    },
  });
}
// Chart.jsの読み込みを待ってからグラフを初期化
function initChartsWithRetry(retries = 5) {
  if (typeof Chart !== "undefined") {
    initCharts();
  } else if (retries > 0) {
    setTimeout(() => initChartsWithRetry(retries - 1), 500);
  }
}

// ページが読み込まれるたびに初期化
document.addEventListener("turbo:load", () => {
  initReceiptUpload();
  initImagePreview();
  initFlatpickr();
  initValidationClear();
  initChartsWithRetry();
});

// バリデーションエラーはturbo:loadが発火しないためturbo:renderで補完
document.addEventListener("turbo:render", () => {
  initValidationClear();
});

// モーダルを閉じたときにフォームをリセット
document.addEventListener("turbo:load", () => {
  const addModal = document.getElementById("addItemModal");
  if (addModal) {
    addModal.addEventListener("hidden.bs.modal", () => {
      const form = addModal.querySelector("form");
      if (form) {
        form.reset();
        form
          .querySelectorAll(".is-invalid")
          .forEach((el) => el.classList.remove("is-invalid"));
        form.querySelectorAll(".invalid-feedback").forEach((el) => el.remove());
      }
      const fp = document.getElementById(
        "expense_item_occurred_on",
      )?._flatpickr;
      if (fp) fp.clear();
      const previewCard = document.getElementById("preview-card");
      const uploadZone = document.getElementById("upload-zone");
      if (previewCard) previewCard.classList.add("d-none");
      if (uploadZone) uploadZone.classList.remove("d-none");
      const ocrBtn = document.getElementById("ocr-btn");
      if (ocrBtn) ocrBtn.classList.add("d-none");
      const receiptId = document.getElementById("selected_receipt_id");
      if (receiptId) receiptId.value = "";
    });
  }
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
