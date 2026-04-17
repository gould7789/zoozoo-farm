// 動物リストをリアルタイムでフィルタリングするコントローラー
// 種名・個体名の部分一致で絞り込む
// カテゴリ内の全アイテムが非表示になった場合はカテゴリブロック（details要素）も非表示にする
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "item", "empty"]

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    let visibleCount = 0

    this.itemTargets.forEach((item) => {
      const text = item.dataset.searchText.toLowerCase()
      const match = text.includes(query)
      item.classList.toggle("hidden", !match)
      if (match) visibleCount++
    })

    // カテゴリブロック（details要素）単位で表示を制御
    // カテゴリ内に表示中のアイテムが1件もなければカテゴリごと非表示にする
    this.element.querySelectorAll("details").forEach((details) => {
      const hasVisible = [ ...details.querySelectorAll("[data-search-target='item']") ]
        .some((item) => !item.classList.contains("hidden"))
      details.classList.toggle("hidden", !hasVisible)
    })

    // 検索結果が0件の場合は「見つかりません」メッセージを表示
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visibleCount > 0)
    }
  }
}
