// 記録を持つユーザーの削除ボタン — 送信せず案内アラートのみ表示するコントローラー
// turbo_confirmはwindow.confirm()なので必ず[OK][キャンセル]の2ボタンになる
// 「確認ボタンのみ」の案内はwindow.alert()でしか作れず、alertはフォームを送信しない
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { message: String }

  notify(event) {
    event.preventDefault()
    window.alert(this.messageValue)
  }
}
