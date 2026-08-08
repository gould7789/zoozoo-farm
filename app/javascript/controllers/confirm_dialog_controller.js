// turbo_confirmのダイアログをブラウザ標準のwindow.confirm()から置き換える
// Turbo.config.forms.confirm は (message, form, submitter) を受け取りawaitされる
// Turbo.setConfirmMethod も同じ値を設定するが、非推奨警告をコンソールに出すため使わない
import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["message", "cancel"]

  connect() {
    Turbo.config.forms.confirm = (message) => this.open(message)
  }

  // 案内のみ（送信しない）— blocked_delete から Outlet 経由で呼ばれる
  notify(message) {
    this.open(message, { cancellable: false })
  }

  open(message, { cancellable = true } = {}) {
    this.messageTarget.textContent = message
    this.cancelTarget.classList.toggle("hidden", !cancellable)
    // returnValueは閉じた後も値が残るため毎回リセットする
    // 忘れると前回の"confirm"が残り、次にESCで閉じても送信されてしまう
    this.element.returnValue = ""
    this.element.showModal()

    return new Promise((resolve) => {
      // ESCキーやバックドロップで閉じた場合はreturnValueが"confirm"にならない
      this.element.addEventListener(
        "close",
        () => resolve(this.element.returnValue === "confirm"),
        { once: true }
      )
    })
  }

  // バックドロップをクリックするとイベントのtargetはdialog自身になる
  // paddingを内側のformに寄せてあるので、dialog自身が対象＝バックドロップと判定できる
  closeOnBackdrop(event) {
    if (event.target === this.element) this.element.close("cancel")
  }
}
