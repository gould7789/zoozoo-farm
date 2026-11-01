// 폼 이중 전송 방지 — 누른 뒤 버튼을 비활성화하고 로딩 문구를 띄운다
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
