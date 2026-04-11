// テーブル行クリックでページ遷移するコントローラー
// インラインonclick属性を排除し、CSP準拠のイベント処理に変更
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  navigate() {
    window.location.href = this.urlValue
  }
}
