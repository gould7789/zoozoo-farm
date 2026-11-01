// 공지 본문에 붙는 이미지를 올리기 전에 브라우저에서 줄인다.
// Action Text 의 기본 리스너는 window 에 달려 있어, 에디터 요소에 붙인 이쪽이 먼저 달린다.
// 왜 이렇게 하는지는 .claude/rules/notes/notice.md
import { Controller } from "@hotwired/stimulus"
import { AttachmentUpload } from "@rails/actiontext"

// 긴 변의 상한. 본문 표시 폭(:detail 의 1200px)보다 조금 크게 잡는다
const MAX_EDGE = 1600
const JPEG_QUALITY = 0.85
// 다시 굽지 않고 그대로 통과시키는 형식 — 축소가 필요 없으면 원본이 덜 상한다
const PASS_THROUGH_TYPES = [ "image/jpeg", "image/png", "image/webp" ]

export default class extends Controller {
  async attach(event) {
    const { attachment, target } = event
    if (!attachment.file) return

    // 기본 window 리스너에 넘기지 않는다. 빼면 원본과 축소본이 두 벌 올라간다
    event.stopPropagation()

    const file = await this.#downscale(attachment.file)
    this.#upload(attachment, target, file)
  }

  // 줄이지 못하면 원본을 돌려준다 — 여기서 멈추면 붙여넣기 자체가 안 된다
  async #downscale(file) {
    if (!file.type.startsWith("image/")) return file

    let bitmap
    try {
      // imageOrientation 을 빼면 EXIF 회전이 날아가 사진이 옆으로 눕는다
      bitmap = await createImageBitmap(file, { imageOrientation: "from-image" })
    } catch {
      return file
    }

    try {
      const longEdge = Math.max(bitmap.width, bitmap.height)
      // 축소가 필요 없으면 JPEG 로 다시 굽지 않는다 — 글자가 번지고 투명도만 잃는다
      if (longEdge <= MAX_EDGE && PASS_THROUGH_TYPES.includes(file.type)) return file

      const scale = Math.min(1, MAX_EDGE / longEdge)
      const canvas = document.createElement("canvas")
      canvas.width = Math.round(bitmap.width * scale)
      canvas.height = Math.round(bitmap.height * scale)

      const context = canvas.getContext("2d")
      // JPEG 은 투명도를 못 가진다. 안 칠하면 투명 부분이 검게 가라앉는다
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

  // actiontext/index.js 의 기본 처리를 따라간다. 다른 점은 둘.
  //   1. 세 번째 인자로 줄인 파일을 넘긴다
  //   2. 실패 문구를 한국어로 바꾸고 깨진 첨부를 본문에서 뺀다 — 조용히 remove() 만 하면
  //      이미지가 사라진 걸 모른 채 공지가 저장된다
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
