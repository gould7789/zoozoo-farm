// フラッシュメッセージを3秒後に自動でフェードアウトするコントローラー
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 接続後3秒でフェードアウト開始
    setTimeout(() => {
      this.element.style.transition = "opacity 0.5s ease"
      this.element.style.opacity = "0"

      // フェードアウト完了後に要素を削除
      setTimeout(() => {
        this.element.remove()
      }, 500)
    }, 3000)
  }
}
