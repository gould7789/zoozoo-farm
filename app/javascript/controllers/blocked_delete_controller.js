// 기록을 가진 사용자의 삭제 버튼 — 전송하지 않고 안내만 띄운다
// 지울 수 없다고 알리기만 하므로 [취소]가 필요 없다 — confirm_dialog 의 안내 모드를 쓴다
// 다이얼로그가 body 직하라 Outlet 으로 참조한다 (.claude/rules/common/views.md)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { message: String }
  static outlets = [ "confirm-dialog" ]

  notify(event) {
    event.preventDefault()
    this.confirmDialogOutlet.notify(this.messageValue)
  }
}
