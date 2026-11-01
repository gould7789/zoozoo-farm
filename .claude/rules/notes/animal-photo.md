---
paths:
  - "app/models/animal.rb"
  - "app/controllers/animal_photos_controller.rb"
  - "app/javascript/controllers/photo_crop_controller.js"
  - "app/javascript/controllers/image_downscale_controller.js"
  - "app/views/animals/_form.html.erb"
---

# 동물 사진 — 파이프라인과 판단

**전체 설명은 `docs/active-storage.md` (336줄)에 있다.** 테이블 구조, variant 가 언제 만들어지나, N+1 실측, 다이렉트 업로드로 입구가 두 개가 된 경위 — 그쪽을 본다.

여기에는 **코드를 고칠 때 걸리는 것**만 적는다.

## 왜 JPEG·PNG·WebP 만인가

**Render 의 libvips 가 HEIC 를 못 읽어 variant 생성이 실패한다.** iPhone 기본 설정이 HEIC 라 그냥 두면 아이폰 사용자가 전부 막힌다.

그래서 **브라우저에서 JPEG 로 바꿔 보낸다**(`image_downscale_controller.js`). 모델의 형식 검증은 그 JS 가 실패했을 때의 최종 방어선이다. 둘 중 하나만 있으면 안 된다.

| 층 | 역할 |
| --- | --- |
| JS | HEIC → JPEG 변환, 1600px 축소 |
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
