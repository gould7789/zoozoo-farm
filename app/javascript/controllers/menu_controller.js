// 헤더의 보조 동작을 담는 「더보기」 메뉴
// <div data-controller="menu"> 안에 버튼과 패널을 둔다
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel"]

  connect() {
    // 바인딩을 보관하는 이유는 removeEventListener 가 같은 참조를 요구하기 때문이다
    this.closeOnOutside = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    this.closeOnEscape = (event) => {
      if (event.key === "Escape") this.close()
    }
    document.addEventListener("click", this.closeOnOutside)
    document.addEventListener("keydown", this.closeOnEscape)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutside)
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  toggle() {
    this.panelTarget.classList.contains("hidden") ? this.open() : this.close()
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    if (this.panelTarget.classList.contains("hidden")) return

    this.panelTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
    // 닫을 때 포커스를 버튼으로 돌린다. 안 그러면 사라진 요소에 포커스가 남아
    // 다음 Tab 이 문서 맨 앞으로 튄다
    if (this.element.contains(document.activeElement)) this.buttonTarget.focus()
  }
}
