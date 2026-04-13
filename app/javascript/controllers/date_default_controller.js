// 日付フィールドに今日の日付・日時をデフォルト値として設定するコントローラー
// 新規作成フォームでのみ動作（編集フォームは既存値を保持）
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]

  connect() {
    // フィールドが空の場合のみセット（編集フォームの既存値を上書きしない）
    this.fieldTargets.forEach((field) => {
      if (!field.value) {
        field.value = field.type === "datetime-local" ? this.nowDatetime() : this.today()
      }
    })
  }

  // YYYY-MM-DD形式（date型フィールド用）
  today() {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, "0")
    const day = String(now.getDate()).padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  // YYYY-MM-DDTHH:MM形式（datetime-local型フィールド用）
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
