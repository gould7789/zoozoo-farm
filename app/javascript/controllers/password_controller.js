// 비밀번호 표시·숨김 전환
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "eyeOn", "eyeOff"]

  toggle() {
    const isPassword = this.inputTarget.type === "password"
    this.inputTarget.type = isPassword ? "text" : "password"
    this.eyeOnTarget.classList.toggle("hidden", isPassword)
    this.eyeOffTarget.classList.toggle("hidden", !isPassword)
  }
}
