// 테이블 행을 눌러 페이지를 옮긴다
// 인라인 onclick 을 쓰지 않는 이유는 CSP 때문이다
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  navigate() {
    window.location.href = this.urlValue
  }
}
