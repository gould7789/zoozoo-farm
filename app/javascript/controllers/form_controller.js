// フォームの二重送信を防止するコントローラー
// 送信ボタンをクリック後、ボタンを無効化してローディングテキストを表示する
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]

  submit() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.textContent = "저장 중..."
    }
  }
}
