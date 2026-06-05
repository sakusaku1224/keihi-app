// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

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
