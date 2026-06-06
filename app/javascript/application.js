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
    const reader = new FileReader();

    // コールバック関数
    reader.onload = function () {
      // 画像srcに変換後の文字列セット
      previewImg.src = reader.result;
      // アップロードゾーンを非表示
      uploadZone.classList.add("d-none");
      // プレビューカード表示
      previewCard.classList.remove("d-none");
      // OCRボタンを表示
      document.getElementById("ocr-btn").classList.remove("d-none");
    };
    // 変換開始
    reader.readAsDataURL(file);
  }

  // 画像削除・初期状態に戻す
  function clearPreview() {
    previewCard.classList.add("d-none");
    uploadZone.classList.remove("d-none");
    // ファイルinputをリセット
    receiptFileInput.value = "";
    currentFile = null;
    document.getElementById("ocr-btn").classList.add("d-none");
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
}

// ページが読み込まれるたびに初期化
document.addEventListener("turbo:load", () => {
  initReceiptUpload();
});
