---
paths:
  - "app/models/animal.rb"
  - "app/controllers/animal_photos_controller.rb"
  - "app/javascript/controllers/photo_crop_controller.js"
  - "app/views/animals/_form.html.erb"
---

# 동물 사진 — 파이프라인과 판단

**전체 설명은 `docs/active-storage.md` (336줄)에 있다.** 테이블 구조, variant 가 언제 만들어지나, N+1 실측, 다이렉트 업로드로 입구가 두 개가 된 경위 — 그쪽을 본다.

여기에는 **코드를 고칠 때 걸리는 것**만 적는다.

## 왜 JPEG·PNG·WebP 만인가

**Render 의 libvips 가 HEIC 를 못 읽어 variant 생성이 실패한다.** iPhone 기본 설정이 HEIC 라 그냥 두면 아이폰 사용자가 전부 막힌다.

그래서 **브라우저에서 JPEG 로 바꿔 보낸다**(`photo_crop_controller.js`. 공지 본문 쪽은 `image_downscale_controller.js` 이고 `notes/notice.md` 에 있다). 모델의 형식 검증은 그 JS 가 실패했을 때의 최종 방어선이다. 둘 중 하나만 있으면 안 된다.

| 층 | 역할 |
| --- | --- |
| JS | HEIC → JPEG 재인코딩, 1600px 축소 |
| 모델 | 변환이 실패한 것을 막는다 |

`MAX_PHOTO_BYTES = 15MB` 도 같은 성격이다. **축소를 강제하는 장치가 아니라 안전망**이다 — JS 가 들으면 수백KB 로 도착한다.

## `preprocessed: true` 를 안 쓴다

잡 워커가 없다(`:async`). variant 는 **처음 참조할 때** 만들어지고 그 뒤로는 저장된 것을 재쓴다. 첫 조회가 느린 대신 워커를 안 둔다 — 직원 10명 미만 규모의 판단이다.

## `purge` 와 `purge_later`

삭제는 **동기(`purge`)로 한다.** `purge_later` 는 무료 플랜 인스턴스가 잠드는 시점에 잡이 사라져 **스토리지에 고아 파일이 남는다.** S3 DELETE 1회라 기다려도 체감되지 않는다.

> 같은 이유로 고아 blob 을 청소하는 장치가 없다. 규모에서 나온 판단이다.

## 검증 에러 때 사진이 사라져 보이는 것

`update` 가 검증에서 떨어지면 `@animal.photo` 는 **저장되지 않은 첨부**를 가리킨다. 저장된 사진을 따로 다시 읽지 않으면 **지워지지 않았는데 지워진 것처럼 보인다.**

```ruby
@saved_photo = Animal.find(@animal.id).photo
```

## 화면에 낼 때는 proxy 를 쓴다

`rails_service_blob_url` 은 스토리지로 **리다이렉트**하는 라우트다. **CSP 는 리다이렉트 뒤의 호스트를 보므로** `img_src 'self'` 아래에서 깨진다. 같은 오리진으로 중계하는 `rails_service_blob_proxy_url` 을 쓴다. (`.claude/rules/notes/notice.md` 의 CSP 절과 같은 함정이다)

## 자르기 화면이 하는 일

사진을 고르면 `<dialog>` 로 자르기 화면을 띄우고, 끌어서 옮기고 슬라이더·휠·핀치로 키워 원 안에 넣게 한다. 「완료」에서 **원에 외접하는 정사각형을 JPEG 로 다시 인코딩해 input 의 파일을 갈아끼운다.**

자르기 하나로 세 가지를 같이 치운다.

| 문제 | 어떻게 |
| --- | --- |
| 전송량과 서버 메모리 (512MB, 워커 없음) | 1600px·JPEG 재인코딩 |
| iPhone 의 HEIC | 재인코딩하면서 형식이 바뀐다 |
| 아바타 구도 | CSS 의 가운데 자르기로는 **머리가 잘린다** |

화면은 전부 `canvas` 에 그린다. 미리보기에 `blob:` URL 을 쓰면 **CSP 의 `img_src` 에 막힌다.**

### 표시 상태를 참·거짓 하나로 두면 안 된다

「파일을 골랐나」와 「미리보기를 만들었나」는 **다른 축**이다.

| 선택 | 미리보기 | 화면 |
| --- | --- | --- |
| 있음 | 있음 | 자르기 완료 |
| 없음 | — | 저장된 사진 + 서버 삭제 버튼 |
| 있음 | 없음 | **디코드 실패.** 취소만 낸다 |

하나로 합치면 세 번째를 표현할 수 없다. 그리고 **선택 중에 서버 삭제 버튼을 내면 안 된다** — 사용자가 「선택 취소」인 줄 알고 누르면 저장된 사진이 지워진다.

### 디코드에 실패해도 막지 않는다

Windows Chrome 의 HEIC 처럼 `createImageBitmap` 이 떨어지는 형식이 있다. 거기서 멈추면 **붙여넣기 자체가 안 된다.** 원본을 그대로 보내고 크기의 최종 방어선은 서버 검증에 맡긴다.

`imageOrientation: "from-image"` 를 빼면 **EXIF 회전이 날아가 스마트폰 사진이 옆으로 눕는다.**

### 스크롤바를 먼저 없애고 연다

순서가 반대면 다이얼로그를 그린 직후 뷰포트 폭이 바뀌어 `w-[92vw]` 와 가운데 정렬이 다시 계산된다. 사용자에게는 **열린 순간의 덜컥거림**으로 보이고, 자동 테스트에서는 그 틈에 클릭이 들어가 옆 요소를 누른다.
