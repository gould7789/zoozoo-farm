---
paths:
  - "app/models/notice.rb"
  - "app/controllers/notices_controller.rb"
  - "app/views/notices/**/*.erb"
  - "app/javascript/controllers/image_downscale_controller.js"
  - "db/migrate/*_migrate_notice_body_to_rich_text.rb"
  - "db/migrate/*_add_title_to_notices.rb"
---

# 공지 게시판 — 왜 이렇게 생겼나

PR #134·#136·#138. 본문을 평문에서 Action Text 리치텍스트로 바꾸고 이미지 첨부를 붙였다.

## 본문은 `notices` 테이블에 없다

```
notices                      action_text_rich_texts
┌──────────────┐             ┌─────────────────────────────┐
│ id           │◄────────────│ record_id                   │
│ title        │             │ record_type = 'Notice'      │
│ category     │             │ name       = 'content'      │
│ body   (보관)│             │ body       = <p>…</p>       │
└──────────────┘             └─────────────────────────────┘
                              UNIQUE (record_type, record_id, name)
```

`has_rich_text :content`는 컬럼을 만들지 않는다. **다른 테이블로 가는 연결**을 만든다.

다형(polymorphic) 구조라 **외래 키 제약을 걸 수 없다** — `record_id`가 어느 테이블을 가리키는지 DB가 모른다. Active Storage도 같은 구조다.

## `:body`가 아니라 `:content`로 지은 이유

`has_rich_text`는 `class_eval`로 **모델 클래스에 직접** 접근자를 정의한다.

```ruby
# actiontext/lib/action_text/attribute.rb
class_eval <<-CODE
  def #{name}
    rich_text_#{name} || build_rich_text_#{name}
  end
CODE
```

컬럼 접근자는 `Notice::GeneratedAttributeMethods`라는 **모듈**에 들어간다. 조상 체인에서 클래스가 모듈보다 위에 오므로, `:body`로 지으면 **기존 `notices.body` 컬럼이 가려진다.**

```
Notice                              ← class_eval 이 여기에 정의 (이긴다)
└ Notice::GeneratedAttributeMethods ← 컬럼 접근자는 여기 (가려진다)
```

이름을 나눈 덕에 **2단계 이관**이 가능해졌다.

| 단계 | 내용 |
| --- | --- |
| PR 1 (완료) | `body`를 읽지도 쓰지도 않는 **보관용**으로 남긴 채 `content`로 전환 |
| PR 2 (예정) | 운영 확인 후 `body` 컬럼 드롭 |

PR 1 상태에서는 `git revert` 한 번으로 **원본 평문이 살아 있는 상태**로 돌아온다. **이름 선택이 곧 롤백 설계였다.**

> `notices.body`는 아직 남아 있다. 읽지도 쓰지도 않는다. 드롭은 별도 PR.

## 임베드 이미지 검증이 모델에 있는 이유

본문 이미지는 **다이렉트 업로드**로 들어온다 — 브라우저가 Supabase에 직접 PUT하고 서버는 바이트를 보지 못한다. **폼을 거치지 않으므로 폼 검증을 통과하지 않는다.**

검증 시점에 `content.embeds`는 **아직 비어 있다**(리치텍스트 저장 콜백에서 채워진다). 그래서 본문 HTML에서 `attachables`를 직접 꺼낸다.

### 두 가지를 본다

**① blob이 아닌 첨부를 막는다.** 손으로 만든 `<action-text-attachment url="...">`는 `RemoteImage`가 되어 `grep(ActiveStorage::Blob)`에 걸리지 않고 `<img src="외부URL">`로 그려진다. 재현했다.

```
POST /notices  url="https://evil.example/track.png"
→ 저장 성공, 검증 통과
→ 렌더: <img width="1" height="1" src="https://evil.example/track.png">
```

지금은 CSP의 `img-src`가 막아 실해가 없다. 고친 이유는 **방어가 CSP 한 겹**이라서다.

**② content_type은 신고값이 아니다.** `ActiveStorage::Attached::Changes`가 첨부를 조립할 때 `identify_without_saving`으로 앞 4KB를 읽어 재판정한다. HEIC를 `image/jpeg`로 위장해 올려 확인했다 — 검증이 본 값은 `image/heic`였다.

**문서화된 보장이 아니라 Rails 내부 동작**이라 위장 파일 spec으로 고정해뒀다.

## `excerpt`가 `to_plain_text`를 안 쓰는 이유

`to_plain_text`는 첨부를 1건씩 sgid로 다시 끌어와 평문 표현을 만든다. 목록에서 쓰면 **공지 수만큼 쿼리가 는다**(실측 1건당 2쿼리, 9 → 15).

HTML에서 만들되 두 가지를 처리한다.

| 처리 | 왜 |
| --- | --- |
| 태그를 **공백으로 치환** 후 제거 | `strip_tags`는 블록 경계에 공백을 안 넣는다. 그냥 벗기면 `<div>테스트</div><div>굿</div>` → `"테스트굿"` |
| `Nokogiri...text`로 실체 참조 복원 | 평문에서 이관한 본문에 `&lt;`가 들어 있다. 남기면 ERB가 이중 이스케이프해 화면에 `&lt;`로 보인다. `&nbsp;`까지 풀린다 |

`photo_count`도 같은 이유로 `body.attachables`가 아니라 **선읽기되는 `content.embeds`**를 쓴다.

## 데이터 이관에서 걸린 것

| 함정 | 내용 |
| --- | --- |
| `simple_format`의 기본 살균 | **태그를 벗기고 안의 텍스트만 남겨** 원문을 조용히 변형한다. `html_escape` 후 `sanitize: false`로 넘겨야 한다 |
| `notices.body`의 NOT NULL | 컬럼을 남기는 것과 제약을 남기는 것은 다르다. `change_column_null`을 같이 넣지 않으면 **신규 작성이 DB에서 떨어진다** |
| `<<~SQL.squish` | 값 안의 개행까지 뭉갠다. `down`에서 평문을 복원할 때 줄이 전부 사라지는 **실제 버그**였다 |
| 제목 백필 | 1행째가 아니라 **첫 비어있지 않은 줄**을 쓴다. 첨부만 있는 공지는 평문이 개행으로 시작한다 |

## 더 자세한 것

- `docs/active-storage.md` — 이미지 파이프라인 전체, 다이렉트 업로드와 폼 업로드의 차이
- 노션 학습보고서 #91~#94
