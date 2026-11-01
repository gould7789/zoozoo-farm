// turbo_confirm 의 다이얼로그를 window.confirm() 에서 갈아끼운다
// Turbo.config.forms.confirm 은 (message, form, submitter) 를 받고 await 된다
// Turbo.setConfirmMethod 도 같은 값을 넣지만 콘솔에 비권장 경고를 내므로 쓰지 않는다
import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["message", "cancel"]

  connect() {
    Turbo.config.forms.confirm = (message) => this.open(message)
  }

  // 안내만 (전송하지 않는다) — blocked_delete 가 Outlet 으로 부른다
  notify(message) {
    this.open(message, { cancellable: false })
  }

  open(message, { cancellable = true } = {}) {
    this.messageTarget.textContent = message
    this.cancelTarget.classList.toggle("hidden", !cancellable)
    // returnValue 는 닫은 뒤에도 남으므로 매번 비운다.
    // 빠뜨리면 지난번 "confirm" 이 남아, 다음에 ESC 로 닫아도 전송된다
    this.element.returnValue = ""
    this.element.showModal()

    return new Promise((resolve) => {
      // ESC 나 배경으로 닫으면 returnValue 가 "confirm" 이 되지 않는다
      this.element.addEventListener(
        "close",
        () => resolve(this.element.returnValue === "confirm"),
        { once: true }
      )
    })
  }

  // 배경을 누르면 이벤트의 target 이 dialog 자신이 된다.
  // padding 을 안쪽 form 에 줬으므로 dialog 자신이 대상이면 배경으로 판정할 수 있다
  closeOnBackdrop(event) {
    if (event.target === this.element) this.element.close("cancel")
  }
}
