// 프로필 사진을 원형으로 자르는 편집 화면.
// 자르기 하나로 전송량·HEIC·아바타 구도 세 가지를 같이 치운다.
// 판단 근거는 .claude/rules/notes/animal-photo.md
import { Controller } from "@hotwired/stimulus"

const MAX_OUTPUT = 1600
const JPEG_QUALITY = 0.85
const MAX_ZOOM = 4
// 자르기 원의 지름 (편집 캔버스에 대한 비율)
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

  // 파일 선택 → 디코드되면 자르기 화면을 연다
  async select() {
    const file = this.inputTarget.files[0]
    if (!file) return

    this.originalName = file.name
    this.#releaseBitmap()

    try {
      // imageOrientation 을 빼면 EXIF 회전이 날아가 사진이 옆으로 눕는다
      this.bitmap = await createImageBitmap(file, { imageOrientation: "from-image" })
    } catch {
      // 디코드 못 하는 형식(Windows Chrome 의 HEIC 등)은 원본 그대로 보내고
      // 서버 검증에 맡긴다. 다만 표시는 되돌린다 — 지난 자르기가 남아 있으면
      // 다른 사진을 고른 것처럼 보인다
      this.#showState({ selected: true, previewed: false })
      return
    }

    const stage = this.stageTarget
    this.diameter = stage.width * CIRCLE_RATIO
    // 확대율 1 일 때 원이 사진의 짧은 변에 꼭 들어간다
    this.minScale = this.diameter / Math.min(this.bitmap.width, this.bitmap.height)
    this.zoom = 1
    this.zoomTarget.value = 1
    this.centerX = this.bitmap.width / 2
    this.centerY = this.bitmap.height / 2

    this.#draw()
    // 스크롤바를 먼저 없애고 연다 — 순서가 반대면 열린 순간 레이아웃이 한 번 더 움직인다
    document.body.classList.add("overflow-hidden")
    this.dialogTarget.showModal()
  }

  // 「완료」— 원에 외접하는 정사각형을 잘라 input 에 반영한다
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

  // 「취소」 또는 ESC — 선택 자체를 취소한다
  cancel() {
    this.inputTarget.value = ""
    this.#showState({ selected: false, previewed: false })
    this.#close()
  }

  // 미저장 선택분만 취소한다. 서버에는 아무것도 보내지 않으므로 확인 모달을 내지 않는다
  clear() {
    this.inputTarget.value = ""
    this.#showState({ selected: false, previewed: false })
  }

  zoomInput() {
    this.#setZoom(Number(this.zoomTarget.value))
  }

  wheel(event) {
    event.preventDefault()
    this.#setZoom(this.zoom * Math.exp(-event.deltaY * 0.002))
  }

  // pointer 이벤트로 마우스·터치·펜을 한 번에 다룬다. 손가락 1개면 이동, 2개면 확대
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
      // 표시 크기와 캔버스 내부 해상도의 차를 보정한 뒤 원본 좌표로 환산한다
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

  // 원에 외접하는 정사각형의 반변 (원본 픽셀 단위)
  #halfSide() {
    return this.diameter / (2 * this.minScale * this.zoom)
  }

  // 자르기 범위가 사진 밖으로 나가지 않도록 중심을 제한한다
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

    // 원의 가운데에 사진의 (centerX, centerY) 가 오도록 그린다
    context.setTransform(scale, 0, 0, scale, size / 2 - this.centerX * scale, size / 2 - this.centerY * scale)
    context.drawImage(this.bitmap, 0, 0)
    context.setTransform(1, 0, 0, 1, 0, 0)

    // 원 바깥을 어둡게 한다 (evenodd 로 원을 뚫는다)
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

  // 폼의 원형 미리보기에 자르기 결과를 옮긴다
  #showPreview(source) {
    const preview = this.previewTarget
    preview.getContext("2d").drawImage(source, 0, 0, preview.width, preview.height)
    this.#showState({ selected: true, previewed: true })
  }

  // 표시는 「파일을 골랐나」와 「미리보기를 만들었나」 2축으로 정해진다 —
  // 하나로 합치면 디코드 실패 상태를 표현할 수 없다 (notes/animal-photo.md)
  //
  //   선택 O · 미리보기 O … 자르기 완료
  //   선택 X             … 저장된 사진과 서버 삭제를 낸다
  //   선택 O · 미리보기 X … 디코드 실패. 취소만 낸다
  #showState({ selected, previewed }) {
    this.previewTarget.hidden = !previewed
    this.clearTarget.hidden = !selected
    // 선택 중에 서버 삭제를 내면, 취소하려다 저장된 사진을 지운다
    if (this.hasCurrentTarget) this.currentTarget.hidden = selected
    if (this.hasDestroyTarget) this.destroyTarget.hidden = selected
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
