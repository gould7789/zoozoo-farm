// テキストエリアの高さを入力内容に合わせて自動調整するコントローラー
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.resize()
  }

  resize() {
    // 一度高さをリセットしてからscrollHeightを取得することで正確な高さを計算
    this.element.style.height = "auto"
    this.element.style.height = `${this.element.scrollHeight}px`
  }
}
