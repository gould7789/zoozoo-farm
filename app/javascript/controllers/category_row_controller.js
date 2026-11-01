// 카테고리 행의 인라인 편집 — 보기 모드와 편집 모드를 바꾼다
// 서버를 거치지 않는다 (DOM 의 표시와 숨김만)
// 자기 행 안에서만 움직이므로 id 로 행을 찾을 필요가 없다
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
