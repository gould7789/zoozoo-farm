// 送信前に画像をブラウザ側で縮小し、JPEGに変換するコントローラー
//
// 目的は2つある。
//   1. 転送量とサーバーのメモリ消費を下げる（無料プランは512MB、ジョブワーカーが無い）
//   2. iPhoneのHEICをJPEGに変換する（RenderのlibvipsはHEICを読めない）
//
// 変換はあくまで最適化なので、失敗しても原本をそのまま送る。
// 形式とサイズの最終判断はサーバー側の検証が行う。
import { Controller } from "@hotwired/stimulus"

const MAX_EDGE = 1600
const JPEG_QUALITY = 0.85
// サーバーが受け付ける形式。これ以外は縮小後に大きくなっても必ず差し替える。
const ALLOWED_TYPES = [ "image/jpeg", "image/png", "image/webp" ]

export default class extends Controller {
  static targets = ["input"]

  async compress() {
    const file = this.inputTarget.files[0]
    if (!file) return

    try {
      const blob = await this.#toResizedJpeg(file)
      if (!blob) return

      // HEICはJPEGにすると大きくなることがあるが、それでも変換しないと
      // サーバーで弾かれる。形式が許可外なら容量に関係なく差し替える。
      const mustConvert = !ALLOWED_TYPES.includes(file.type)
      if (mustConvert || blob.size < file.size) {
        this.#replaceInputFile(blob, file.name)
      }
    } catch {
      // デコード不可・メモリ不足・ブラウザ差異のいずれでも原本のまま送る
    }
  }

  async #toResizedJpeg(file) {
    // imageOrientationを指定しないとEXIFの回転情報が失われ、
    // スマホで撮った写真が横倒しで保存される
    const bitmap = await createImageBitmap(file, { imageOrientation: "from-image" })
    const scale = Math.min(1, MAX_EDGE / Math.max(bitmap.width, bitmap.height))
    const width = Math.round(bitmap.width * scale)
    const height = Math.round(bitmap.height * scale)

    const canvas = document.createElement("canvas")
    canvas.width = width
    canvas.height = height
    canvas.getContext("2d").drawImage(bitmap, 0, 0, width, height)
    bitmap.close()

    return new Promise((resolve) => {
      canvas.toBlob(resolve, "image/jpeg", JPEG_QUALITY)
    })
  }

  // input要素のファイルは直接代入できないためDataTransfer経由で差し替える
  #replaceInputFile(blob, originalName) {
    const name = originalName.replace(/\.[^.]+$/, "") + ".jpg"
    const transfer = new DataTransfer()
    transfer.items.add(new File([ blob ], name, { type: "image/jpeg" }))
    this.inputTarget.files = transfer.files
  }
}
