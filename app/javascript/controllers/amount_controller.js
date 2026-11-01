// 금액 칸에 세 자리 구분을 입력 중에 넣어 보여준다 — 전송은 숫자만 보낸다
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "hidden"]

  connect() {
    // 수정 폼에 기존 값이 있으면 구분을 넣어 보여준다
    if (this.hiddenTarget.value) {
      this.displayTarget.value = this.format(this.hiddenTarget.value)
    }
  }

  input() {
    const raw = this.displayTarget.value.replace(/[^0-9]/g, "")
    this.displayTarget.value = raw ? this.format(raw) : ""
    // 전송되는 건 hidden 쪽의 숫자다
    this.hiddenTarget.value = raw
  }

  format(value) {
    return Number(value).toLocaleString("ko-KR")
  }
}
