// 別のDOMツリーにあるモーダルを開くためのコントローラー
// モーダルはcontent_for :modalでbody直下にレンダされるため、
// ボタンとは<body>以外に共通の祖先を持てない — Outletで参照する
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static outlets = ["modal"]

  open() {
    this.modalOutlet.open()
  }
}
