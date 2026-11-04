// 모바일에서 Trix 툴바를 1줄로 접고, 「더보기」로 나머지를 펼친다
//
// 버튼을 팝업으로 빼내지 않는 이유는 Trix 가 <trix-toolbar> 안의 요소에만
// 핸들러를 걸기 때문이다 — 밖으로 꺼내면 눌러도 서식이 걸리지 않는다.
// 어느 버튼을 숨기는지는 app/assets/tailwind/application.css 에 있다
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // trix-initialize 가 Stimulus 연결보다 먼저 날아가는 경우가 있다 — 실측 20회 중 2회
  // 「⋯」 가 아예 없었다. 그때는 이벤트를 영영 못 받으므로 여기서 직접 확인한다.
  // editor 가 서 있으면 초기화가 끝난 것이다
  connect() {
    if (this.element.editor) this.addToggle()
  }

  // Trix 가 툴바를 만든 뒤에 불린다 (data-action 으로 trix-initialize 에 건다)
  addToggle() {
    const toolbar = this.element.toolbarElement
    const row = toolbar?.querySelector(".trix-button-row")
    if (!row || row.querySelector("[data-trix-toolbar-toggle]")) return

    const group = document.createElement("span")
    group.className = "trix-button-group trix-toolbar-toggle-group"

    const button = document.createElement("button")
    button.type = "button"
    button.className = "trix-button trix-toolbar-toggle"
    button.setAttribute("data-trix-toolbar-toggle", "")
    button.setAttribute("aria-expanded", "false")
    button.setAttribute("aria-label", "서식 더보기")
    button.title = "서식 더보기"
    button.tabIndex = -1
    button.textContent = "⋯"
    // tabIndex = -1 은 Tab 순서에서만 뺀다 — 눌렀을 때의 포커스는 그대로 간다.
    // 실측: 이 버튼을 누르면 activeElement 가 BUTTON 이 되고, Trix 자신의 버튼은
    // TRIX-EDITOR 를 유지한다. Trix 가 mousedown 을 preventDefault 하기 때문이다.
    // 모바일에서 포커스가 나가면 키보드가 내려가고 본문의 선택이 풀린다
    button.addEventListener("mousedown", (event) => event.preventDefault())
    button.addEventListener("click", () => this.toggle(toolbar, button))

    group.appendChild(button)
    row.appendChild(group)
  }

  toggle(toolbar, button) {
    const open = toolbar.classList.toggle("trix-toolbar--expanded")
    button.setAttribute("aria-expanded", String(open))
  }
}
