// 記録を持つユーザーの削除ボタン — 送信せず案内ダイアログのみ表示するコントローラー
// 削除できないことを伝えるだけなので[취소]は不要 — confirm_dialogの案内モードを使う
// ダイアログはレイアウトのbody直下にあり共通の祖先を持てないためOutletで参照する
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { message: String }
  static outlets = [ "confirm-dialog" ]

  notify(event) {
    event.preventDefault()
    this.confirmDialogOutlet.notify(this.messageValue)
  }
}
