// 다른 DOM 트리에 있는 모달을 연다
// 모달이 body 직하라 버튼과 <body> 말고는 공통 조상이 없다 — Outlet 으로 참조한다
// 왜 body 직하인지는 .claude/rules/common/views.md
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static outlets = ["modal"]

  open() {
    this.modalOutlet.open()
  }
}
