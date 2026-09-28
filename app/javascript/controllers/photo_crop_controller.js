// プロフィール写真を円形に切り抜くための編集画面を出すコントローラー
//
// 写真を選ぶと<dialog>で切り抜き画面を開き、ドラッグで移動・スライダー/ホイール/
// ピンチで拡大して見せたい部分を円の中に収めさせる。「완료」で円に外接する正方形を
// JPEGに再エンコードし、inputのファイルを差し替える。
//
// 切り抜きと同時に3つの問題を片付けている。
//   1. 転送量とサーバーのメモリ消費（無料プランは512MB、ジョブワーカーが無い）
//   2. iPhoneのHEIC（RenderのlibvipsはHEICを読めない）
//   3. アバターの構図（CSSの中央切り抜きでは頭が欠ける）
//
// 画面はすべてcanvasに描く。プレビューにblob: URLを使うと
// CSPのimg_src（:self, :data）に阻まれるため。
import { Controller } from "@hotwired/stimulus"

const MAX_OUTPUT = 1600
const JPEG_QUALITY = 0.85
const MAX_ZOOM = 4
// 切り抜き円の直径（編集キャンバスに対する比率）
const CIRCLE_RATIO = 0.86

export default class extends Controller {
  static targets = ["input", "dialog", "stage", "zoom", "preview", "current", "clear", "destroy"]

  connect() {
    this.bitmap = null
    this.pointers = new Map()
  }

  disconnect() {
    this.#releaseBitmap()
  }

  // ファイル選択 → デコードできたら切り抜き画面を開く
  async select() {
    const file = this.inputTarget.files[0]
    if (!file) return

    this.originalName = file.name
    this.#releaseBitmap()

    try {
      // imageOrientationを指定しないとEXIFの回転情報が失われ、
      // スマホで撮った写真が横倒しになる
      this.bitmap = await createImageBitmap(file, { imageOrientation: "from-image" })
    } catch {
      // デコードできない形式（WindowsのChromeでのHEIC等）は原本のまま送り、
      // サーバー側の検証に委ねる
      return
    }

    const stage = this.stageTarget
    this.diameter = stage.width * CIRCLE_RATIO
    // 拡大率1のとき、円が写真の短辺にちょうど収まる
    this.minScale = this.diameter / Math.min(this.bitmap.width, this.bitmap.height)
    this.zoom = 1
    this.zoomTarget.value = 1
    this.centerX = this.bitmap.width / 2
    this.centerY = this.bitmap.height / 2

    this.#draw()
    this.dialogTarget.showModal()
    document.body.classList.add("overflow-hidden")
  }

  // 「완료」— 円に外接する正方形を切り出してinputに反映する
  async confirm() {
    const half = this.#halfSide()
    const side = Math.min(Math.round(half * 2), MAX_OUTPUT)

    const output = document.createElement("canvas")
    output.width = side
    output.height = side
    output.getContext("2d").drawImage(
      this.bitmap,
      this.centerX - half, this.centerY - half, half * 2, half * 2,
      0, 0, side, side
    )

    const blob = await new Promise((resolve) => output.toBlob(resolve, "image/jpeg", JPEG_QUALITY))
    if (!blob) return this.cancel()

    const name = this.originalName.replace(/\.[^.]+$/, "") + ".jpg"
    const transfer = new DataTransfer()
    transfer.items.add(new File([ blob ], name, { type: "image/jpeg" }))
    this.inputTarget.files = transfer.files

    this.#showPreview(output)
    this.#close()
  }

  // 「취소」またはESC — 選択自体を取り消す
  cancel() {
    this.inputTarget.value = ""
    this.#close()
  }

  // 未保存の選択を取り消し、保存済みの写真があればその表示に戻す。
  // サーバーには何も送らないので確認モーダルは出さない
  clear() {
    this.inputTarget.value = ""
    this.#showPendingState(false)
  }

  zoomInput() {
    this.#setZoom(Number(this.zoomTarget.value))
  }

  wheel(event) {
    event.preventDefault()
    this.#setZoom(this.zoom * Math.exp(-event.deltaY * 0.002))
  }

  // pointerイベントでマウス・タッチ・ペンを一括で扱う。
  // 指1本ならドラッグ移動、2本ならピンチ拡大
  pointerDown(event) {
    event.preventDefault()
    this.stageTarget.setPointerCapture(event.pointerId)
    this.pointers.set(event.pointerId, { x: event.clientX, y: event.clientY })
    if (this.pointers.size === 2) {
      this.pinch = { distance: this.#pinchDistance(), zoom: this.zoom }
    }
  }

  pointerMove(event) {
    const previous = this.pointers.get(event.pointerId)
    if (!previous) return
    event.preventDefault()
    this.pointers.set(event.pointerId, { x: event.clientX, y: event.clientY })

    if (this.pointers.size === 1) {
      // 表示サイズとキャンバスの内部解像度の差を補正してから元画像の座標に換算する
      const ratio = this.stageTarget.width / this.stageTarget.clientWidth
      const scale = this.minScale * this.zoom
      this.centerX -= (event.clientX - previous.x) * ratio / scale
      this.centerY -= (event.clientY - previous.y) * ratio / scale
      this.#clampCenter()
      this.#draw()
    } else if (this.pointers.size === 2 && this.pinch) {
      this.#setZoom(this.pinch.zoom * this.#pinchDistance() / this.pinch.distance)
    }
  }

  pointerUp(event) {
    this.pointers.delete(event.pointerId)
    if (this.pointers.size < 2) this.pinch = null
  }

  #setZoom(value) {
    this.zoom = Math.min(Math.max(value, 1), MAX_ZOOM)
    this.zoomTarget.value = this.zoom
    this.#clampCenter()
    this.#draw()
  }

  // 円に外接する正方形の半辺（元画像のピクセル単位）
  #halfSide() {
    return this.diameter / (2 * this.minScale * this.zoom)
  }

  // 切り抜き範囲が写真の外にはみ出さないよう中心を制限する
  #clampCenter() {
    const half = this.#halfSide()
    this.centerX = Math.min(Math.max(this.centerX, half), this.bitmap.width - half)
    this.centerY = Math.min(Math.max(this.centerY, half), this.bitmap.height - half)
  }

  #pinchDistance() {
    const [ a, b ] = [ ...this.pointers.values() ]
    return Math.hypot(a.x - b.x, a.y - b.y)
  }

  #draw() {
    const stage = this.stageTarget
    const size = stage.width
    const scale = this.minScale * this.zoom
    const context = stage.getContext("2d")

    context.setTransform(1, 0, 0, 1, 0, 0)
    context.fillStyle = "#111827"
    context.fillRect(0, 0, size, size)

    // 円の中心に写真の(centerX, centerY)が来るように描く
    context.setTransform(scale, 0, 0, scale, size / 2 - this.centerX * scale, size / 2 - this.centerY * scale)
    context.drawImage(this.bitmap, 0, 0)
    context.setTransform(1, 0, 0, 1, 0, 0)

    // 円の外側を暗くする（evenoddで円をくり抜く）
    const radius = this.diameter / 2
    context.beginPath()
    context.rect(0, 0, size, size)
    context.arc(size / 2, size / 2, radius, 0, Math.PI * 2)
    context.fillStyle = "rgba(0, 0, 0, 0.55)"
    context.fill("evenodd")

    context.beginPath()
    context.arc(size / 2, size / 2, radius, 0, Math.PI * 2)
    context.strokeStyle = "rgba(255, 255, 255, 0.9)"
    context.lineWidth = 2
    context.stroke()
  }

  // フォーム上の円形プレビューに切り抜き結果を写す
  #showPreview(source) {
    const preview = this.previewTarget
    preview.getContext("2d").drawImage(source, 0, 0, preview.width, preview.height)
    this.#showPendingState(true)
  }

  // 未保存の選択があるかどうかで、写真と「사진 삭제」の出し分けを切り替える。
  // 選択中は新しいプレビューと取り消しボタン、無ければ保存済みの写真とサーバー削除
  #showPendingState(pending) {
    this.previewTarget.hidden = !pending
    this.clearTarget.hidden = !pending
    if (this.hasCurrentTarget) this.currentTarget.hidden = pending
    if (this.hasDestroyTarget) this.destroyTarget.hidden = pending
  }

  #close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
    document.body.classList.remove("overflow-hidden")
    this.pointers.clear()
    this.pinch = null
  }

  #releaseBitmap() {
    if (this.bitmap) {
      this.bitmap.close()
      this.bitmap = null
    }
  }
}
