// モーダルの開閉を管理するコントローラー
// 同一コントローラー内: data-action="click->modal#open/close"
// 外部からの呼び出し: openModal("modal-element-id") グローバル関数を使用
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

// モーダルコントローラーが別の要素に存在する場合の外部呼び出し用ヘルパー
window.openModal = function (modalId) {
  const el = document.getElementById(modalId)
  if (!el) return
  el.querySelector("[data-modal-target='overlay']").classList.remove("hidden")
  el.querySelector("[data-modal-target='panel']").classList.remove("hidden")
  document.body.classList.add("overflow-hidden")
}

// カテゴリ行のインライン編集モード切替
// サーバーラウンドトリップなし — DOMの表示・非表示のみ
window.startEdit = function (categoryId) {
  const row = document.getElementById(`category_row_${categoryId}`)
  if (!row) return
  row.querySelector("[data-view-mode]").classList.add("hidden")
  row.querySelector("[data-edit-mode]").classList.remove("hidden")
  row.querySelector("input[type='text']").focus()
}

window.cancelEdit = function (categoryId) {
  const row = document.getElementById(`category_row_${categoryId}`)
  if (!row) return
  row.querySelector("[data-edit-mode]").classList.add("hidden")
  row.querySelector("[data-view-mode]").classList.remove("hidden")
}
