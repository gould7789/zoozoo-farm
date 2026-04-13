// 金額入力フィールドに3桁区切りカンマをリアルタイム表示するコントローラー
// 表示はカンマ付き、フォーム送信時は数値のみ送信する
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "hidden"]

  connect() {
    // 編集フォームで既存値がある場合はカンマ付きで表示
    if (this.hiddenTarget.value) {
      this.displayTarget.value = this.format(this.hiddenTarget.value)
    }
  }

  input() {
    // 数値以外の文字を除去
    const raw = this.displayTarget.value.replace(/[^0-9]/g, "")
    // カンマ付きで表示フィールドを更新
    this.displayTarget.value = raw ? this.format(raw) : ""
    // 隠しフィールドに数値のみをセット（フォーム送信用）
    this.hiddenTarget.value = raw
  }

  format(value) {
    return Number(value).toLocaleString("ko-KR")
  }
}
