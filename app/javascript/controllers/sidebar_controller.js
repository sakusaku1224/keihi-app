import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggle() {
    document.querySelector(".sidebar").classList.toggle("collapsed");
    // サイドバーが縮んだ時に、メインコンテンツとトップバーも連動
    document.querySelector(".main-content").classList.toggle("sidebar-collapsed");
    document.querySelector(".top-bar").classList.toggle("sidebar-collapsed");
  }
}
