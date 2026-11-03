// 모달 열고 닫기
//   같은 트리 안에서   data-action="click->modal#open/close"
//   다른 트리에서      modal_opener_controller 가 Outlet 으로 open() 을 부른다
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay"]

  connect() {
    // ESC 로 닫는다. <dialog> 라면 공짜로 따라오는 것인데 이 모달은 직접 만들었다.
    // 바인딩을 보관하는 이유는 removeEventListener 가 같은 참조를 요구하기 때문이다
    this.closeOnEscape = (event) => {
      if (event.key === "Escape" && !this.panelTarget.classList.contains("hidden")) {
        this.close()
      }
    }
    document.addEventListener("keydown", this.closeOnEscape)
  }

  disconnect() {
    document.removeEventListener("keydown", this.closeOnEscape)
  }

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

  // 배경을 누르면 닫는다
  closeOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }
}
