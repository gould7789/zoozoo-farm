// 동물 목록을 입력 중에 거른다 — 종명·개체명 부분 일치
// 서버를 거치지 않는다. 관 하나의 동물은 전부 이미 그려져 있다 (notes/zone-accordion.md)
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

    // 카테고리 안에 보이는 항목이 하나도 없으면 카테고리(details)째로 숨긴다
    this.element.querySelectorAll("details").forEach((details) => {
      const hasVisible = [ ...details.querySelectorAll("[data-search-target='item']") ]
        .some((item) => !item.classList.contains("hidden"))
      details.classList.toggle("hidden", !hasVisible)
    })

    // 결과가 0건이면 안내 문구를 띄운다
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visibleCount > 0)
    }
  }
}
