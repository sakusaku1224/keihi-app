import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggle() {
    document.querySelector(".sidebar").classList.toggle("collapsed");
    // サイドバーが縮んだ時に、メインコンテンツも連動
    document
      .querySelector(".main-content")
      .classList.toggle("sidebar-collapsed");
  }
}
