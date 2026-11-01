// textarea 높이를 입력 내용에 맞춰 늘린다
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.resize()
  }

  resize() {
    // 높이를 한 번 되돌린 뒤 scrollHeight 를 읽어야 정확한 값이 나온다
    this.element.style.height = "auto"
    this.element.style.height = `${this.element.scrollHeight}px`
  }
}
