// お知らせ本文に貼る画像を、アップロード前にブラウザ側で縮小するコントローラー。
//
// Action Text の既定はこうなっている（actiontext/index.js）。
//
//   addEventListener("trix-attachment-add", event => { ... new AttachmentUpload(...) })
//
// bare の addEventListener なので登録先は window である。イベントは
// <trix-editor> から window へ上がるので、エディタ要素に付けたこのリスナーが先に走る。
// そこで stopPropagation() すれば既定の送信を止められ、縮小したファイルで
// AttachmentUpload をこちらから組み立て直せる。
//
// 縮小する理由は photo_crop_controller.js と同じ。
// 無料プランはメモリ512MBでジョブワーカーが無く、スマホの原本（数MB）が
// そのまま届くと variant 生成が重い。現場の主経路は
// カカオトーク → PCにダウンロード → アップロード で、原本サイズのまま来る。
import { Controller } from "@hotwired/stimulus"
import { AttachmentUpload } from "@rails/actiontext"

// 長辺の上限。本文の表示幅（variant :detail の 1200px）より少し大きく取り、
// 高解像度ディスプレイでも粗く見えないようにする
const MAX_EDGE = 1600
const JPEG_QUALITY = 0.85
// 再エンコードせずそのまま通す形式。
// libvipsが読めて、縮小が不要なら原本の方が劣化しない
const PASS_THROUGH_TYPES = [ "image/jpeg", "image/png", "image/webp" ]

export default class extends Controller {
  async attach(event) {
    const { attachment, target } = event
    if (!attachment.file) return

    // 既定の window リスナーに渡さない。これを外すと原本と縮小版が
    // 二重にアップロードされる
    event.stopPropagation()

    const file = await this.#downscale(attachment.file)
    this.#upload(attachment, target, file)
  }

  // 縮小できなければ原本を返す。Windows Chrome の HEIC のように
  // デコードできない形式があり、ここで止めると貼り付け自体ができなくなる。
  // 大きさの最終防衛線はサーバー側の検証に委ねる
  async #downscale(file) {
    if (!file.type.startsWith("image/")) return file

    let bitmap
    try {
      // imageOrientation を指定しないと EXIF の回転情報が落ち、
      // スマホで撮った写真が横倒しになる
      bitmap = await createImageBitmap(file, { imageOrientation: "from-image" })
    } catch {
      return file
    }

    try {
      const longEdge = Math.max(bitmap.width, bitmap.height)
      // 縮小が要らないならJPEGに焼き直さない。
      // ロゴやスクリーンショットのPNGを再エンコードすると文字が滲み、
      // 透過も失うのに、サイズはほとんど変わらない
      if (longEdge <= MAX_EDGE && PASS_THROUGH_TYPES.includes(file.type)) return file

      const scale = Math.min(1, MAX_EDGE / longEdge)
      const canvas = document.createElement("canvas")
      canvas.width = Math.round(bitmap.width * scale)
      canvas.height = Math.round(bitmap.height * scale)

      const context = canvas.getContext("2d")
      // JPEGは透過を持てない。塗らずに書き出すと透過部分が黒く沈むため、
      // 本文の背景と同じ白で埋めてから描く
      context.fillStyle = "#ffffff"
      context.fillRect(0, 0, canvas.width, canvas.height)
      context.drawImage(bitmap, 0, 0, canvas.width, canvas.height)

      const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/jpeg", JPEG_QUALITY))
      if (!blob) return file

      const name = file.name.replace(/\.[^.]+$/, "") + ".jpg"
      return new File([ blob ], name, { type: "image/jpeg" })
    } finally {
      bitmap.close()
    }
  }

  // actiontext/index.js の既定処理をなぞる。違いは2点。
  //   1. 第3引数に縮小したファイルを渡す
  //   2. 失敗時のメッセージを韓国語にし、壊れた差し込みを本文から外す
  //
  // 黙って remove() だけすると、画像が消えたことに気付かないまま
  // 공지が保存される。既定の alert(error) は英語のスタックが出るので置き換える
  #upload(attachment, target, file) {
    const upload = new AttachmentUpload(attachment, target, file)
    const onProgress = (event) => attachment.setUploadProgress(event.detail.progress)

    target.addEventListener("direct-upload:progress", onProgress)

    upload.start()
      .then((attributes) => attachment.setAttributes(attributes))
      .catch(() => {
        attachment.remove()
        alert("이미지 업로드에 실패했습니다. 다시 시도해주세요.")
      })
      .finally(() => target.removeEventListener("direct-upload:progress", onProgress))
  }
}
