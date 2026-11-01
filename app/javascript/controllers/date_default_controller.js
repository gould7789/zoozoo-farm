// 날짜 칸에 오늘 날짜나 일시를 기본값으로 넣는다 — 작성 폼에서만 동작한다
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]

  connect() {
    // 비어 있을 때만 넣는다 — 수정 폼의 기존 값을 덮어쓰지 않는다
    this.fieldTargets.forEach((field) => {
      if (!field.value) {
        field.value = field.type === "datetime-local" ? this.nowDatetime() : this.today()
      }
    })
  }

  // YYYY-MM-DD — date 칸용
  today() {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, "0")
    const day = String(now.getDate()).padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  // YYYY-MM-DDTHH:MM — datetime-local 칸용
  nowDatetime() {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, "0")
    const day = String(now.getDate()).padStart(2, "0")
    const hours = String(now.getHours()).padStart(2, "0")
    const minutes = String(now.getMinutes()).padStart(2, "0")
    return `${year}-${month}-${day}T${hours}:${minutes}`
  }
}
