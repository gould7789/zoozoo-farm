// プロフィール写真を正方形に切り抜いてから送信するコントローラー
//
// 選択された画像を正方形の枠に表示し、ドラッグで見せたい部分を選ばせる。
// 確定した領域だけをJPEGに再エンコードしてinputのファイルを差し替える。
//
// 切り抜きと同時に3つの問題を片付けている。
//   1. 転送量とサーバーのメモリ消費（無料プランは512MB、ジョブワーカーが無い）
//   2. iPhoneのHEIC（RenderのlibvipsはHEICを読めない）
//   3. アバターの見た目（横長の写真がCSSで中央を切られて頭が欠ける）
//
// 変換はあくまで最適化なので、失敗しても原本をそのまま送る。
// 形式とサイズの最終判断はサーバー側の検証が行う。
import { Controller } from "@hotwired/stimulus"

const MAX_OUTPUT = 1600
const JPEG_QUALITY = 0.85
// サーバーが受け付ける形式。これ以外は容量に関係なく必ず差し替える。
const ALLOWED_TYPES = [ "image/jpeg", "image/png", "image/webp" ]

export default class extends Controller {
  static targets = ["input", "editor", "canvas", "hint"]

  connect() {
    this.bitmap = null
    this.offset = 0
  }

  disconnect() {
    this.#releaseBitmap()
  }

  async select() {
    const file = this.inputTarget.files[0]
    if (!file) return

    this.originalFile = file
    this.#releaseBitmap()

    try {
      // imageOrientationを指定しないとEXIFの回転情報が失われ、
      // スマホで撮った写真が横倒しになる
      this.bitmap = await createImageBitmap(file, { imageOrientation: "from-image" })
    } catch {
      // デコードできない形式はそのまま送り、サーバー側の検証に委ねる
      this.editorTarget.hidden = true
      return
    }

    // 切り抜く正方形の一辺。長い方の軸だけがドラッグで動く
    this.side = Math.min(this.bitmap.width, this.bitmap.height)
    this.maxOffset = Math.max(this.bitmap.width, this.bitmap.height) - this.side
    this.offset = Math.round(this.maxOffset / 2) // 初期位置は中央

    const output = Math.min(this.side, MAX_OUTPUT)
    this.canvasTarget.width = output
    this.canvasTarget.height = output

    this.editorTarget.hidden = false
    this.hintTarget.hidden = this.maxOffset === 0
    this.#draw()
    await this.#commit()
  }

  // ドラッグ開始 — pointerイベントでマウスとタッチをまとめて扱う
  startDrag(event) {
    if (!this.bitmap || this.maxOffset === 0) return
    event.preventDefault()
    this.dragging = true
    this.dragStart = this.#pointerPosition(event)
    this.offsetStart = this.offset
    this.canvasTarget.setPointerCapture(event.pointerId)
  }

  drag(event) {
    if (!this.dragging) return
    event.preventDefault()

    // 表示サイズと元画像のスケール差を補正する
    const scale = this.side / this.canvasTarget.clientWidth
    const moved = (this.#pointerPosition(event) - this.dragStart) * scale
    this.offset = this.#clamp(Math.round(this.offsetStart - moved))
    this.#draw()
  }

  async endDrag(event) {
    if (!this.dragging) return
    this.dragging = false
    this.canvasTarget.releasePointerCapture(event.pointerId)
    await this.#commit()
  }

  // 横長なら横方向、縦長なら縦方向にだけ動かせる
  #pointerPosition(event) {
    return this.bitmap.width > this.bitmap.height ? event.clientX : event.clientY
  }

  #clamp(value) {
    return Math.min(Math.max(value, 0), this.maxOffset)
  }

  #draw() {
    const landscape = this.bitmap.width > this.bitmap.height
    const sx = landscape ? this.offset : 0
    const sy = landscape ? 0 : this.offset
    const size = this.canvasTarget.width

    const context = this.canvasTarget.getContext("2d")
    context.clearRect(0, 0, size, size)
    context.drawImage(this.bitmap, sx, sy, this.side, this.side, 0, 0, size, size)
  }

  // 現在の切り抜き結果をinputのファイルに反映する
  async #commit() {
    const blob = await new Promise((resolve) => {
      this.canvasTarget.toBlob(resolve, "image/jpeg", JPEG_QUALITY)
    })
    if (!blob) return

    // HEICはJPEGにすると大きくなることがあるが、変換しないとサーバーで弾かれる。
    // 形式が許可外なら容量に関係なく差し替える。
    const mustConvert = !ALLOWED_TYPES.includes(this.originalFile.type)
    const cropped = this.maxOffset > 0
    if (!mustConvert && !cropped && blob.size >= this.originalFile.size) return

    const name = this.originalFile.name.replace(/\.[^.]+$/, "") + ".jpg"
    const transfer = new DataTransfer()
    transfer.items.add(new File([ blob ], name, { type: "image/jpeg" }))
    this.inputTarget.files = transfer.files
  }

  #releaseBitmap() {
    if (this.bitmap) {
      this.bitmap.close()
      this.bitmap = null
    }
  }
}
