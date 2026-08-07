// カテゴリ行のインライン編集 — 表示モードと編集モードを切り替える
// サーバーラウンドトリップなし（DOMの表示・非表示のみ）
// 自分の行の中だけで動くため、以前のようにidで行を探す必要がない
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["view", "edit", "input"]

  startEdit() {
    this.viewTarget.classList.add("hidden")
    this.editTarget.classList.remove("hidden")
    this.inputTarget.focus()
  }

  cancelEdit() {
    this.editTarget.classList.add("hidden")
    this.viewTarget.classList.remove("hidden")
  }
}
