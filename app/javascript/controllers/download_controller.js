// Excel 내보내기 링크 — 누른 뒤 화면이 아무 변화도 주지 않는다
// data-turbo=false 라 전체 내비게이션이고, 다운로드는 페이지를 바꾸지 않는다.
// 판단 근거는 .claude/rules/notes/xlsx-export.md
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label"]
  // label 을 서버에서 받는 이유는 아래 connect() 주석에 있다
  static values = { seconds: { type: Number, default: 4 }, label: String }

  // 잠긴 상태로 Turbo 캐시에 찍힌 페이지가 뒤로가기로 되살아날 수 있다.
  // 캐시 복제는 turbo:before-cache 에 일어나므로 disconnect() 에서 되돌려도 늦다
  connect() {
    this.reset()
  }

  start(event) {
    // 새 탭으로 여는 클릭은 이 페이지의 링크를 잠글 이유가 없다
    if (event.metaKey || event.ctrlKey) return

    // 잠긴 동안의 클릭은 막는다 — 여기서만 preventDefault 한다.
    // 첫 클릭은 그대로 흘려보내야 다운로드가 시작된다
    if (this.busy) {
      event.preventDefault()
      return
    }

    this.busy = true
    this.labelTarget.textContent = "내보내는 중..."
    this.element.classList.add("opacity-60")
    this.element.setAttribute("aria-busy", "true")

    this.timer = setTimeout(() => this.reset(), this.secondsValue * 1000)
  }

  // 메뉴 패널은 DOM 에 그대로 남으므로 되돌리지 않으면 문구가 영원히 바뀐 채가 된다
  reset() {
    clearTimeout(this.timer)
    this.busy = false
    this.labelTarget.textContent = this.labelValue
    this.element.classList.remove("opacity-60")
    this.element.removeAttribute("aria-busy")
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
