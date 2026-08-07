// モーダルの開閉を管理するコントローラー
// 同一コントローラー内: data-action="click->modal#open/close"
// 別のDOMツリーからの呼び出し: modal_opener_controller が Outlet 経由で open() を呼ぶ
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay"]

  open() {
    this.panelTarget.classList.remove("hidden")
    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  // オーバーレイ（背景）クリックで閉じる
  closeOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }
}
