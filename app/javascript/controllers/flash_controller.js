// 플래시 메시지를 3초 뒤에 페이드아웃시킨다
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 붙고 3초 뒤에 시작
    setTimeout(() => {
      this.element.style.transition = "opacity 0.5s ease"
      this.element.style.opacity = "0"

      // 끝나면 요소를 지운다
      setTimeout(() => {
        this.element.remove()
      }, 500)
    }, 3000)
  }
}
