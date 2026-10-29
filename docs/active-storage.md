# 이미지 파이프라인 (Active Storage)

동물 프로필 사진과 공지 본문 이미지가 **어디에 어떻게 저장되고, 화면에 나올 때 무슨 일이 일어나는지**를 적는다.

`has_one_attached` 한 줄 뒤에서 일어나는 일이 보이지 않으면, N+1이 왜 나는지도 보이지 않는다.

1~6은 폼 업로드(동물 사진), 7은 다이렉트 업로드(공지 본문 이미지)다. **둘은 같은 Active Storage를 쓰지만 신뢰 경계가 다른 곳에 있다.**

---

## 1. `animals` 테이블에는 사진 컬럼이 없다

```ruby
# app/models/animal.rb
has_one_attached :photo
```

이 선언은 **컬럼을 만들지 않는다.** 전용 테이블 3개로 관리한다.

```
┌───────────────────────────────┐
│ active_storage_blobs          │  "파일 하나"의 신원
│  id, key, filename,           │
│  content_type, byte_size,     │  실제 바이트는 Supabase에 있고
│  checksum                     │  여기엔 메타데이터만
└───────────────────────────────┘
          ▲ blob_id
┌───────────────────────────────┐
│ active_storage_attachments    │  "그 파일이 어디에 붙었나" (조인 테이블)
│  id, name, blob_id,           │  name        = 'photo'
│  record_type, record_id       │  record_type = 'Animal'
└───────────────────────────────┘  record_id   = 그 동물
          │
          ▼  animals

┌───────────────────────────────┐
│ active_storage_variant_records│  "이 원본의 이 변환본은 만들어뒀다"
│  id, blob_id, variation_digest│  variation_digest = 변환 규칙의 해시
└───────────────────────────────┘  이 레코드도 자기 blob을 갖는다 (변환 결과물)
```

### 왜 `animals.photo_blob_id` 컬럼 하나로 안 하나

**① 파일과 소유자를 분리한다.** blob은 "파일 하나", attachment는 "그 파일이 어디에 붙었나"다. 같은 blob을 여러 곳에 붙일 수 있다.

**② 다형성이다.** `record_type`이 `'Animal'`이면 동물, `'Notice'`면 공지다. **테이블마다 컬럼을 추가하지 않아도** 어디에든 붙는다. 공지에 사진을 붙일 때 마이그레이션이 필요 없다.

---

## 2. variant — 원본에서 파생된 변환본

```ruby
has_one_attached :photo do |attachable|
  attachable.variant :thumb,  resize_to_fill: [ 320, 320 ]
  attachable.variant :detail, resize_to_limit: [ 1200, 1200 ]
end
```

아이폰으로 찍으면 4000×3000이 들어온다. 목록의 32px 동그라미에 그대로 쓸 수 없다.

```
원본 4000×3000 (Supabase, 영원히 그대로)
  ├── :thumb   320×320    목록·프로필 동그라미
  └── :detail  1200×1200  상세 화면
```

**원본은 건드리지 않는다.** 나중에 썸네일을 480으로 키우려면 숫자만 바꾸면 된다.

| | 동작 | 쓰는 곳 |
| --- | --- | --- |
| `resize_to_fill` | 잘라서 채움. **정사각형 보장**, 가장자리 잘림 | 원형 아바타 |
| `resize_to_limit` | 비율 유지하며 줄이기만. 안 잘림 | 상세 화면 |

### 이름을 붙이는 이유 (`:thumb`)

```erb
<%= image_tag animal.photo.variant(resize_to_fill: [320, 320]) %>   쓸 때마다 반복
<%= image_tag animal.photo.variant(:thumb) %>                        이름으로
```

규칙이 모델 한 곳에 있으니 크기를 바꿀 때 뷰를 뒤지지 않아도 된다.

### 언제 만들어지나

**미리 만들지 않는다.** 처음 요청될 때 libvips가 변환하고 그 결과를 저장한다. 두 번째부터는 저장된 것을 쓴다.

```ruby
# preprocessed: true 를 쓰면 업로드 직후 미리 만들 수 있지만,
# 잡 워커가 없는 환경이라 쓰지 않는다 (app/models/animal.rb 주석 참고)
```

---

## 3. 동물 한 마리를 화면에 그릴 때

```erb
<%# app/views/zones/_animal_avatar.html.erb %>
<% if animal.photo.attached? %>
  <%= image_tag animal.photo.variant(:thumb) %>
<% end %>
```

| 단계 | 하는 일 | 쿼리 |
| --- | --- | --- |
| ① `photo.attached?` | attachments에서 `(record_type, record_id, name)` 찾기 | **1회** |
| ② 찾았으면 | 그 `blob_id`로 blobs 조회 | **1회** |
| ③ `variant(:thumb)` | **DB를 안 본다** | 0회 |
| ④ `image_tag` | `<img src="/rails/active_storage/representations/...">` 출력 | 0회 |

### ③에서 DB를 안 보는 이유

`variant(:thumb)`은 그 자리에서 이미지를 만들지도, 찾지도 않는다. **URL을 조립할 뿐**이고 재료는 ②에서 이미 손에 있다.

```
blob의 서명된 id  +  변환 규칙(:thumb)의 해시
        ↓
/rails/active_storage/representations/redirect/<서명된 blob id>/<변환 해시>/animal.jpg
```

`variant_records`를 보는 건 **브라우저가 저 URL로 따로 요청을 보냈을 때**다. 그제서야 "이 blob의 이 변환본 기록이 있나?" 묻고, 없으면 libvips를 돌려 만들고 기록한다.

**HTML 한 장을 그리는 요청과, 이미지 N장을 받는 요청은 별개다.**

---

## 4. N+1

### 어디서 나나

목록을 루프로 돌면 위 표의 ①②가 **마리마다** 반복된다.

```
동물 목록 쿼리 1회
  → 1번 동물: attachments, blobs
  → 2번 동물: attachments, blobs
  → ...                                 마리당 2회
```

### 실측

| | 3마리 | 10마리 |
| --- | --- | --- |
| 썸네일 전 | 7 | 7 |
| 프리로드 없음 | 13 | **27** ← 마리 수에 비례 |
| `with_attached_photo` | 11 | **11** |

### 고치는 법

```ruby
@animals_by_category = @zone.animals.active
                            .includes(:health_records)
                            .with_attached_photo      # ←
                            .order(:species, :name)
                            .group_by(&:animal_category_id)
```

동물을 **먼저 다 읽고**, 그 id를 모아 한 번에 묻는다.

```sql
SELECT * FROM active_storage_attachments WHERE record_id IN (10개 전부);
SELECT * FROM active_storage_blobs       WHERE id        IN (10개 전부);
```

`N번 왕복` → `1번 왕복`. 프리로드는 이게 전부다.

`with_attached_photo`는 `has_one_attached :photo` 선언이 **자동으로 만들어 주는 스코프**다. 직접 쓸 필요가 없다.

### 7 → 11, 4회가 늘어난 것

`with_attached_photo`는 `variant_records`와 그 blob까지 함께 당겨온다. **화면을 그리는 데는 안 쓰는 조회**다(위 ③ 참고). 직접 `includes(photo_attachment: :blob)`로 4회를 아낄 수는 있지만, 표준 스코프를 버릴 만큼은 아니라고 판단했다.

중요한 건 **이 4회가 마리 수에 비례하지 않는다**는 점이다. N+1이 아니다.

### 빠뜨리기 쉬운 자리

`@animals_by_category`를 **두 곳**에서 만든다.

| 파일 | 언제 타나 |
| --- | --- |
| `app/controllers/zones_controller.rb` | 관 상세 페이지를 열 때 |
| `app/controllers/animal_categories_controller.rb` | 카테고리 조작 후 **turbo_stream 재렌더** |

둘째를 빠뜨리면 **페이지를 처음 열 땐 멀쩡한데, 카테고리를 한 번 조작한 뒤부터만** N+1이 난다. 재현 조건이 붙는 만큼 찾기 어렵다.

`spec/requests/zones_spec.rb`에 테스트가 두 개 있는 이유다. turbo_stream 쪽은 `Accept` 헤더를 줘야 한다. 빼면 `format.html`로 떨어져 302에 본문 0바이트가 되고, 쿼리 수가 줄어든 것처럼 보인다.

---

## 5. `collection:`은 N+1과 무관하다

```erb
<% animals.each do |animal| %>
  <%= render "zones/animal_card", animal: animal %>
<% end %>

<%= render partial: "zones/animal_card", collection: animals, as: :animal %>
```

| | 루프 | `collection:` |
| --- | --- | --- |
| 템플릿 찾기 (경로·포맷·핸들러 해석) | N번 | **1번** |
| 그 템플릿으로 HTML 만들기 | N번 | N번 |

**줄어든 건 앞줄뿐이고, 쿼리와는 아무 관계가 없다.** 템플릿 조회에는 캐시도 있어서 애초에 비싸지 않다.

파샬 추출의 진짜 이유는 **중복 제거**다 (`_accordion.html.erb` 234줄 → 114줄).

---

## 6. 이미지가 실제로 오는 경로

```ruby
# config/application.rb
config.active_storage.resolve_model_to_route = :rails_storage_proxy
```

기본값은 `:rails_storage_redirect`로, Supabase의 서명된 URL로 302를 보낸다. 이 프로젝트는 **proxy**를 쓴다.

```
브라우저 → Rails (/rails/active_storage/...) → Supabase에서 받아 → 브라우저에 전달
```

**이유는 CSP다.** `img_src :self, :data`로 묶여 있어 외부 도메인 이미지가 차단된다. proxy를 쓰면 이미지가 전부 자기 도메인에서 나오므로 CSP를 건드리지 않아도 된다.

대가는 **대역폭이 Rails를 통과한다**는 것이다. 사진 수가 늘면 다시 볼 지점이다.

---

## 7. 다이렉트 업로드 — 업로드 경로가 두 개가 됐다

공지 본문 이미지를 넣으면서 **성격이 다른 업로드**가 하나 늘었다.

```
① 동물 프로필 사진 ─ 폼 업로드
   브라우저 ──파일──▶ Rails ──▶ Supabase
                      │
                      └─ 서버가 바이트를 직접 쥔다

② 공지 본문 이미지 ─ 다이렉트 업로드
   브라우저 ──메타데이터만──▶ Rails   "photo.jpg, 10MB, image/jpeg"
   브라우저 ◀──서명된 URL────  Rails
   브라우저 ─────파일──────────────▶ Supabase
                                     │
                                     └─ 서버는 바이트를 보지 못한다
```

②가 2단계인 이유는 간단하다. **파일을 서버에 통과시키지 않으면** 앱 서버의 메모리와 대역을 안 쓴다. 무료 플랜(512MB)에서 수MB짜리 사진이 Puma 스레드를 붙잡고 있지 않게 된다.

대신 **blob 레코드가 파일보다 먼저 생긴다.**

```ruby
# ActiveStorage::DirectUploadsController#create
params.expect(blob: [ :filename, :byte_size, :checksum, :content_type, metadata: {} ])
# → create_before_direct_upload!(...)  검사 없이 INSERT
```

### `content_type`은 브라우저의 신고값이다

①은 `unfurl(io, identify: true)`가 실제 바이트에서 타입을 뽑으므로 브라우저가 뭐라 하든 덮어쓴다. ②는 그 시점에 바이트가 없으니 신고값이 그대로 들어간다.

그래서 **HEIC에 `.jpg`를 붙이고 `image/jpeg`로 신고해** 실측했다.

| 지점 | 값 |
| --- | --- |
| DB의 `content_type` | `"image/jpeg"` (신고값) |
| `identified` | `nil` |
| **모델 검증이 본 값** | **`"image/heic"`, `identified=true`** |
| 결과 | 거부 |

```ruby
# activestorage/lib/active_storage/attached/changes/create_many.rb:10
blobs.each(&:identify_without_saving)
#   └─ 저장소에서 앞 4KB를 내려받아 Marcel로 실체 판정
```

첨부가 모델에 붙는 시점에 Rails가 다시 판정한다. **신고값은 검증까지 도달하지 못한다.**

단 이건 문서화된 보장이 아니라 내부 동작이므로, 위장 파일을 올리는 spec으로 고정해 뒀다(`spec/models/notice_spec.rb`). Rails가 이 동작을 바꾸면 빨개진다.

### 거부돼도 파일은 남는다

```
① 신청      → blob 레코드 생성       ← 여기까지는 성공
② 업로드    → Supabase에 파일 저장    ← 여기까지도 성공
③ 공지 저장 → 검증에서 거부
```

**①②는 이미 끝나 있다.** 아무도 안 가리키는 blob과 파일이 남는다. 잡 워커도 스케줄러도 없어 자동 정리를 넣지 않았다. 치우는 방법은 `ActiveStorage::Blob.unattached` 를 Rake로 돌리는 것이고, 용량이 실제로 차면 그때 넣는다.

### 입구가 늘면 인증도 늘려야 한다

```ruby
class ActiveStorage::DirectUploadsController < ActiveStorage::BaseController
#                                              ↑ ApplicationController가 아니다
```

`before_action :require_login`은 **`ApplicationController`를 상속한 컨트롤러에만** 걸린다. 비로그인으로 찔러 **200 + Supabase 직접 쓰기용 서명 URL**을 받는 것을 재현했다.

```ruby
# config/initializers/active_storage_authentication.rb
Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
    before_action :require_logged_in_user
  end
end
```

`initializer`가 아니라 `to_prepare`인 이유는, 개발 환경의 코드 재로드마다 클래스가 다시 만들어져 한 번만 쓴 패치가 사라지기 때문이다.

**조회 쪽은 그대로 열려 있다.**

| 엔드포인트 | 비로그인 |
| --- | --- |
| `POST /rails/active_storage/direct_uploads` | 302 |
| `GET /rails/active_storage/blobs/proxy/...` | **200** |
| `GET /rails/active_storage/blobs/redirect/...` | **200** |

서명된 URL만 있으면 누구나 이미지를 볼 수 있다. Rails의 의도된 설계(capability URL)이고 URL은 추측 불가라 그대로 뒀다. **"로그인한 직원만"은 업로드에만 해당한다.**

> gem을 추가하면 라우트가 늘어난다. `rails routes`로 늘어난 것을 보고, 그게 우리 인증 안쪽인지 확인한다.

### 본문 이미지는 `:detail`과 같은 치수로 맞췄다

Action Text의 기본 `_blob` 파셜은 이름 없는 variant(`resize_to_limit: [1024, 768]`)를 쓴다. `Animal`의 `:detail`(1200×1200)과 다르면 **variant가 두 벌 생성**되고, 잡 워커가 없는 환경에서는 첫 표시마다 변환이 돈다. 파셜을 덮어 1200×1200으로 통일했다.

---

## 8. 아직 안 본 것

| 항목 | 상태 |
| --- | --- |
| 목록 썸네일의 variant 생성 부하 | 미관측. 사진이 많은 관을 **처음** 열면 그 수만큼 libvips 변환이 3스레드 Puma 뒤에서 일어난다. `loading: "lazy"`로 한 번에 몰리는 양은 줄였고 variant는 한 번 만들면 저장되지만, 잡 워커가 없어 비동기로 뺄 방법이 없다 |
| Supabase 저장 용량·전송량 | 기준선 미측정 |
| 아이폰 실기기 | HEIC 직접 업로드 경로 미검증 |
| Windows Chrome의 공지 이미지 첨부 | 미검증. **현장 주 경로**(카톡 → PC 다운로드 → 업로드)인데 아직 사람이 눌러보지 않았다 |
| 고아 blob 누적량 | 미측정. 검증에 걸린 업로드만 남으므로 양은 적을 것으로 보지만 세어본 적 없다 |
