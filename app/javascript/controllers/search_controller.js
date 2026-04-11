// 動物リストをリアルタイムでフィルタリングするコントローラー
// 種名・個体名の部分一致で絞り込む
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

    // 検索結果が0件の場合は「見つかりません」メッセージを表示
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visibleCount > 0)
    }
  }
}
