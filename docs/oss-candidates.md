# 상류 버그 후보 로그

개발 중 만난 "라이브러리 태생적 결함" 후보를 기록합니다.
작성 기준과 절차는 `zoozoo-farm-image-upload-handoff.md` 8장 참조.

**우회 코드를 커밋하기 전에 반드시 한 항목을 추가할 것.**

---

## 기록 템플릿 (복사해서 사용)

```markdown
## [YYYY-MM-DD] 라이브러리명 버전 — 한 줄 요약

- **증상**:
- **재현 절차**:
  1.
  2.
- **원인 추정**: (파일 경로:행 번호, 해당 코드 인용)
- **상류 이슈 검색 결과**: (없음 / #번호 — open·merged·closed)
- **적용한 우회**: (커밋 해시, 어떤 코드를 넣었는지)
- **판정**: 내 설정 실수 / 상류 버그 후보 / 상류에서 이미 처리됨
- **다음 액션**: (이슈 등록 / PR 작성 / 재현 확인 코멘트 / 없음)
```

---

## 기록

### [2026-08-08경] activestorage 8.1.3.1 — image_processing 2.x 환경에서 부팅 실패

> 참고용 기존 사례. 이번 작업 시작 시점의 배경이자, **놓친 기회의 기록**입니다.

- **증상**: `bin/rails` 계열 명령이 전부 LoadError로 중단
- **재현 절차**:
  1. Rails 8.1.3.1, `config.load_defaults 8.1` (→ `variant_processor`가 `:vips`)
  2. Gemfile에 `image_processing ~> 2.0`, `ruby-vips` 없음
  3. 애플리케이션 부팅
- **원인 추정**: `activestorage/lib/active_storage/engine.rb` — `rescue LoadError`의 `case`가 `/libvips/`와 `/image_processing/`만 매칭. 실제 메시지는 `ImageProcessing::Vips requires the ruby-vips gem...`이라 어디에도 걸리지 않고 `else`의 `raise`로 떨어짐
- **상류 이슈 검색 결과**: **당시 검색하지 않음.** 사후 확인 결과 이슈 #58413(2026-08-08), PR #58414가 2026-08-10 `8-1-stable`에 머지됨. main 대상 #58417은 아직 open
- **적용한 우회**: PR #66 — `config.active_storage.variant_processor = :disabled`
- **판정**: 상류 버그. 진단은 정확했으나 상류에 보고하지 않음
- **다음 액션**: 없음 (기회 종료). 단, 이 우회 설정은 이번 작업에서 제거 대상이며, 관련 미해결 이슈 #58313을 확인할 것

**교훈**: 진단이 맞았어도 우회로 덮으면 기록이 남지 않는다. 우회 코드를 쓰기 전에 상류 검색 5분.

---

### [2026-08-07] actionpack 8.1.3.1 — rate_limit이 카운트 못 하는 스토어에서 조용히 무효화됨

> `7204b89`가 우회를 커밋할 때 남겼어야 할 항목. 2026-08-24에 사후 작성했다.

- **증상**: `rate_limit`을 넣었는데 11번째 로그인이 그냥 성공. 예외도 경고도 로그도 없음
- **재현 절차**:
  1. `config.cache_store = :null_store` (Rails 8.1 `rails new`의 test 환경 기본값)
  2. 컨트롤러에 `rate_limit to: 10, within: 3.minutes, only: :create`
  3. 같은 키로 11회 요청 → 전부 통과
- **원인 추정**: `actionpack/lib/action_controller/metal/rate_limiting.rb:76-77`

  ```ruby
  count = store.increment(cache_key, 1, expires_in: within)
  if count && count > to
  ```

  `count &&` 가드가 nil을 삼킨다. `active_support/cache/null_store.rb:28`의 `increment`는 빈 메서드라 nil을 반환한다.
  `Cache::Store#increment` 기본 구현은 `NotImplementedError`를 던지므로 "갱신된 값을 반환한다"가 원래 계약인데, null_store만 조용히 계약을 벗어난다.
  가드는 v7.2.0(기능 최초 도입) 시점부터 존재하며 v8.0.0 / v8.0.2 / v8.1.0에서도 동일하다.
  캐시 장애 시 전원이 잠기는 것을 피하려는 **의도적 fail-open**으로 보인다.
- **상류 이슈 검색 결과** (GitHub API로 코멘트 11개 전문 대조):
  - PR #50781 (merged) — Kredis에서 `AS::Cache`로 옮긴 PR. `count &&` 가드는 이 PR의 커밋
    `d839ddb`(2024-01-17)에서 들어왔고, **일주일 뒤 같은 스레드에서 결과가 드러났다.**

    | 시각 | 발언 |
    | --- | --- |
    | dhh 01-24 | *"Problem with this in testing is that we default to `null_store`. So the value doesn't persist. So you can't test it."* |
    | byroot 01-24 | *"we could detect when it's `NullStore` and fallback to a `MemoryStore`, but that sounds a bit too brittle."* |
    | dhh 01-25 | *"I think we should default to MemoryStore, but make it a dedicated test instance, and then also ensure #clear is called by default."* |

    **코어 두 명이 해결책에 합의했으나 2년 반이 지나도록 미구현이다.**
    `railties/.../templates/config/environments/test.rb.tt:27`은 지금도 `:null_store`다.
  - Issue #53172 (closed, `more-information-needed`) — memory_store로 바꿨을 때 카운터가 예제 간 누수되는 짝 문제
  - Issue #52823 — `ActionController::API`에 `cache_store`가 없어 rate limit이 동작하지 않는 별건
  - `60d92e4`(2026-01-02, zzak) — rdoc 말미에 테스트용 조언이 **이미 있다.**
    *"For directly testing the behavior of `rate_limit`, you may need to switch the cache store to
    `ActiveSupport::Cache::MemoryStore` for the duration of your test."*
    이 커밋은 그 이전 문구에서 `config.cache_store = :memory_store`를 **일부러 뺐다**
    (제목: "to avoid global cache_store change"). 즉 전역 설정 변경 권고는 폐기된 방향이다.
- **적용한 우회**: `7204b89` — test 환경 `cache_store`를 `:memory_store`로 교체 + `spec/rails_helper.rb`에 `Rails.cache.clear` before 훅 (#53172 대응)
- **판정**: **상류 버그 아님.** fail-open은 의도된 설계이고, 테스트 조언도 이미 문서에 있다.
  빠진 것은 **이유** — 기본 스토어가 세지 않아 제한이 "미검증"이 아니라 "꺼져 있다"는 사실과,
  같은 일이 프로덕션의 fail-open에서도 일어난다는 것
- **다음 액션**: **완료.** [rails/rails#58558](https://github.com/rails/rails/pull/58558) 제출 (2026-08-25).
  `rate_limiting.rb` rdoc에 한 문단 추가. 제출본은 `docs/upstream-pr-rate-limit-docs.md`

**교훈 ①**: 검색 결과 요약을 인용으로 쓰지 말 것. 처음 이 항목에는 *"같은 스레드에서 문서화 제안이
나왔다"* 고 적혀 있었는데 **그런 코멘트는 존재하지 않았다.** 웹 검색 요약이 만들어낸 문장을 검증 없이
옮긴 것이다. 공개 PR 직전에 API로 원문을 대조해서 걸렀다. 상류에 인용할 문구는 반드시 원문에서 가져온다.

**교훈 ②**: 문서를 고치기 전에 **그 문서 전체를 읽을 것.** rdoc 상단만 보고 "테스트 관련 언급이 없다"고
판단해 문단을 넣었는데, Examples 아래에 이미 조언이 있었고 심지어 8개월 전 `60d92e4`가 의도적으로
좁혀놓은 문구와 정면으로 충돌했다. 빌드된 문서 프리뷰를 눈으로 확인해서 잡았다.

**파생 발견 — 같은 가드가 프로덕션에서도 문다 (이쪽은 상류가 아니라 내 설정 실수)**

`production.rb:50`이 `:solid_cache_store`인데 `solid_cache_entries` 테이블이 프로덕션에 존재하지 않았다.
`database.yml`의 `cache:`가 `migrations_paths: db/cache_migrate`를 가리키는데 그 디렉터리가 없어서
`db:migrate`가 아무것도 실행하지 않았고, `db/cache_schema.rb`는 cache 접속이 primary와 같은 DB로 해석되는 바람에
"이미 초기화됨"으로 판정되어 로드되지 않았다.

`DATABASE_URL`이 있으면 URL의 DB명이 `database.yml`의 `database:` 키를 덮어쓴다는 점을 몰랐던 것이 출발점이다.
`zoozoo_farm_production_cache`를 쓰는 줄 알았지만 실제로는 네 config가 전부 같은 Supabase DB를 가리키고 있었다.

로컬에서 `render.yaml`의 빌드를 그대로 재현해 확인한 실측.

```
primary  db="zoozoo_farm_production"  tasks=true  paths=nil
cache    db="zoozoo_farm_production"  tasks=true  paths="db/cache_migrate"   ← 디렉터리 없음
→ db:migrate 후 solid_* 테이블 0개
→ store.increment(...) → ActiveRecord::StatementInvalid: PG::UndefinedTable
```

즉 프로덕션에서는 조용히 통과한 게 아니라 `POST /login`이 500을 냈다. **하지만 fail-open도 같이 살아 있다.**
solid_cache의 `increment`는 `entries.rb:31`에서 `writing_key(key, failsafe: :increment)`로 감싸여 있고
`failsafe_returning` 기본값이 nil이다. `TRANSIENT_ACTIVE_RECORD_ERRORS`에 `ConnectionNotEstablished`가 포함되므로,
Supabase 무료 플랜이 유휴로 내려간 순간 `increment`가 nil을 돌려주고 → `count &&`에서 스킵 → 제한이 꺼진다.
테이블을 만들어도 이 두 번째 실패 모드는 남는다.

**교훈**: fail-open하는 보안 기능은 "동작한다"를 테스트가 증명해주지 않는다.
제한이 걸리는 것만 검증하면, 스토어가 죽었을 때 통과하는 스펙과 구분되지 않는다.
스토어가 실제로 세는지를 별도로 못 박아야 한다.

---

### [2026-08-25] Supabase(PostgREST) — Data API를 끄면 로그가 32초마다 에러로 채워짐

> 우회 코드를 쓴 건 아니라 기록 의무는 없다. **다음에 이 로그를 보고 또 시간을 쓰지 않으려고** 남긴다.

- **증상**: Supabase 로그에 `schema "pg_pgrst_no_exposed_schemas" does not exist` (`3F000`)가 약 32초 간격으로 계속 쌓임
- **재현 절차**:
  1. Supabase 프로젝트에서 Data API를 비활성화 (또는 신규 프로젝트 기본 상태)
  2. Logs 확인
- **원인 추정**: Data API가 꺼지면 PostgREST의 `db-schemas`에 `pg_pgrst_no_exposed_schemas`라는 실재하지 않는 센티넬 스키마가 들어간다. PostgREST가 주기적으로 스키마 캐시를 다시 만들려다 매번 실패하고 로그를 남긴다
- **상류 이슈 검색 결과**: Supabase 공식 트러블슈팅 문서에 명시 — *"should not adversely affect the project, although it may result in additional entries in your logs."* 이슈 supabase/supabase#40617 open
- **적용한 우회**: 없음
- **판정**: **우리 영향 없음.** 이 앱은 `DATABASE_URL`로 Postgres 프로토콜에 직접 붙고 PostgREST를 경유하지 않는다. Data API가 꺼져 있는 편이 맞다 — 쓰지 않는 REST 엔드포인트를 여는 건 공격 표면만 늘린다
- **다음 액션**: 없음. **Data API를 켜서 노이즈를 없애려 하지 말 것.** 로그를 볼 때 필터를 건다

  ```
  event_message NOT LIKE '%pg_pgrst_no_exposed_schemas%'
  ```

**교훈**: 무해한 로그 노이즈도 장애 진단을 방해한다. `PG::UndefinedTable`을 찾아낸 게 로그인 장애 진단의 결정타였는데, 그때 이 빨간 줄들 사이에서 골라냈다. 노이즈는 그 자체로 비용이다.

---
### [2026-08-26] activestorage 8.1.3.1 — 우회를 걷어낸 순간의 LoadError 실측

> [2026-08-08경] 항목의 후속. 그때는 재현 로그를 남기지 않고 우회로 덮었다.
> 이번에 `ruby-vips`를 넣기 직전, **재현이 가능한 마지막 시점에** 실물을 확보했다.

- **증상**: `config.active_storage.variant_processor = :disabled`를 주석 처리하자 앱 초기화가 LoadError로 중단
- **재현 절차**:
  1. `config/application.rb`의 `variant_processor = :disabled`를 주석 처리
  2. `bin/rails runner 'puts 1'` 실행

  `bin/rails -v`는 **통과한다.** 버전 출력은 앱을 부팅하지 않기 때문이다.
  [2026-08-08경] 항목에 "`bin/rails` 계열 명령이 전부 중단"이라고 적혀 있었으나 정확하지 않다.
  초기화를 도는 명령만 죽는다.
- **실측 스택트레이스** (상단 3프레임):

  ```
  image_processing-2.0.2/lib/image_processing/vips.rb:5:in '<compiled>':
    ImageProcessing::Vips requires the ruby-vips gem.
    Please add `gem "ruby-vips", "~> 2.0"` to your Gemfile. (LoadError)
    from activestorage-8.1.3.1/lib/active_storage/transformers/vips.rb:10
    from activestorage-8.1.3.1/lib/active_storage/engine.rb:101
  ```

- **원인 확인** (설치된 gem 소스를 직접 읽음):
  - `activestorage-8.1.3.1/lib/active_storage/engine.rb:105-130` — `rescue LoadError`의 `case error.message`가 `/libvips/`와 `/image_processing/`만 매칭한다.
    실제 메시지는 `ImageProcessing::Vips requires the ruby-vips gem...`이라 **둘 다 안 걸린다.**
    `ImageProcessing`은 CamelCase라 `/image_processing/`에 매칭되지 않고, `ruby-vips`는 `/libvips/`를 포함하지 않는다. → `else`의 `raise`로 떨어진다
  - `activestorage-8.1.3.1/lib/active_storage/transformers/vips.rb:7-8`의 주석은
    *"requiring it here is what raises LoadError when the gem is missing, **which the engine reports as an actionable warning**"* 라고 적혀 있다.
    **주석이 서술하는 의도와 실제 동작이 다르다** — 8장 8-1의 마지막 트리거에 정확히 해당한다
- **상류 이슈 검색 결과**: **이미 수정 완료.** `main`과 `8-1-stable` 양쪽 `engine.rb`를 원문으로 확인했고
  `when /ruby-vips/` · `when /mini_magick/` 분기가 들어가 있다 (#58414, 2026-08-10 머지).
  우리가 밟은 8.1.3.1은 그 이전 릴리스라 아직 재현될 뿐이다.
  - **[2026-08-08경] 항목의 기재를 정정한다.** 거기에 "main 대상 #58417은 아직 open"이라고 적혀 있으나,
    GitHub API로 확인한 #58417의 base는 **`8-1-stable`**이다. 그리고 그 브랜치에는 이미 #58414가 머지돼 있어
    #58417은 중복이다. main에도 같은 분기가 있다
- **적용한 우회**: 없음. `ruby-vips`를 Gemfile에 추가하는 정공법으로 해결
- **판정**: **상류 버그였으나 상류에서 이미 처리됨.** 기여 기회 없음
- **다음 액션**: 없음. 8.1.4 릴리스에 수정이 포함될 것이므로 별도 대응 불필요

**교훈**: "아직 안 고쳐졌다"는 기록도 유통기한이 있다. 인계 문서의 이슈 목록을 그대로 믿고 착수했다면
이미 닫힌 문 앞에서 시간을 썼을 것이다. 착수 시점에 **번호별 현재 상태를 API로 다시 조회**하는 게 5분이다.

---

### [2026-08-26] activestorage 8.1.3.1 — `:disabled`가 이미지 분석기까지 끈다 (#58313 정적 확인)

- **증상**: `variant_processor = :disabled`이면 첨부 이미지의 `width`/`height` 메타데이터가 기록되지 않는다
- **원인 확인** (설치된 gem 소스):
  - `analyzer/image_analyzer/vips.rb:10` — `def self.accept?(blob) = super && ActiveStorage.variant_processor == :vips`
  - `analyzer/image_analyzer/image_magick.rb:17` — `super && ActiveStorage.variant_processor == :mini_magick`

  `:disabled`면 **두 분석기 모두 수락하지 않는다.** `engine.rb:28`의 기본 analyzers 목록에는 들어 있지만
  실제로 선택되는 것이 없어 이미지 분석 자체가 건너뛰어진다. 리사이즈를 끄려고 넣은 설정이
  메타데이터 기록까지 함께 끄는 셈이다
- **상류 이슈 검색 결과**: 이슈 #58313 open, 수정 PR #58314 open. **3주 넘게 코멘트 0건**
- **적용한 우회**: 없음 (이번 작업에서 `:disabled` 자체를 제거)
- **판정**: **상류 버그 후보. 아직 열려 있다**
- **다음 액션**: 최소 재현 앱으로 실제 동작을 확인하고 #58313에 결과 코멘트.
  위 정적 확인만으로는 근거가 약하다 — **실제로 첨부해서 `blob.metadata`가 비는 것을 봐야 한다**


### [2026-09-02] Rails 가이드 — S3 호환 서비스의 `force_path_style`이 문서화되어 있지 않다

- **증상**: 가이드대로 `endpoint`만 지정해 Supabase Storage에 연결하면 업로드가 실패한다. **에러가 원인과 전혀 다른 곳을 가리킨다**
- **재현 절차**:
  1. `config/storage.yml`에 S3 서비스를 만들고 `endpoint`를 `https://<ref>.supabase.co/storage/v1/s3`로 지정
  2. `force_path_style`은 **지정하지 않는다** (가이드에 언급이 없으므로)
  3. `service.upload(key, io, checksum:)` 실행
- **실측 결과**:

  ```
  Seahorse::Client::NetworkingError
  SSL_connect returned=1 errno=0 peeraddr=172.64.155.33:443
    state=error: ssl/tls alert handshake failure (SSL alert number 40)
  ```

  `force_path_style: true`를 넣으면 즉시 정상 동작한다(upload → download → delete 왕복 확인).
- **원인 추정**: aws-sdk-s3는 기본적으로 가상 호스트 방식으로 URL을 만든다. 즉 `zoozoo-farm-production.<ref>.supabase.co`로 접속을 시도한다.
  Supabase의 와일드카드 인증서 `*.supabase.co`는 **라벨 한 단계만** 커버하므로 이 3단계 서브도메인은 포함되지 않는다. 그래서 HTTP 응답을 받기 전에 TLS 핸드셰이크 단계에서 끊긴다
- **왜 문제인가**: 흔히 "403이 난다"고 알려져 있으나 **실제로는 403조차 아니다.** TLS 에러라서 디버깅하는 사람은 프록시 설정, OpenSSL 버전, 인증서 체인을 의심하게 된다. 스토리지 설정 옵션 하나가 빠졌다는 곳으로는 도달하기 어렵다
- **상류 문서 확인** (원문 대조):
  - `guides/source/active_storage_overview.md` 1281행 부근 — *"You can also connect to an S3-compatible object storage API such as DigitalOcean Spaces by providing an `endpoint`"* 라고만 적혀 있고 예시에도 `endpoint`만 있다. **`force_path_style`은 가이드 전체에 한 번도 등장하지 않는다**
  - DigitalOcean Spaces는 가상 호스트 방식을 지원하므로 그 예시만 보면 문제가 드러나지 않는다. 경로 방식만 지원하는 서비스(Supabase, MinIO 등)에서만 발생한다
- **적용한 우회**: 없음. `force_path_style: true`는 우회가 아니라 정규 옵션이다
- **판정**: **코드 버그 아님. 문서 누락.** 옵션은 aws-sdk-s3가 제공하며 Active Storage가 그대로 전달한다. 빠진 것은 "언제 필요한지"에 대한 설명이다
- **다음 액션**: rails/rails에 가이드 PR.
  **착수 전 반드시 S3 섹션 전문을 읽을 것** — #58558에서 상단만 보고 판단했다가 8개월 전 결정과 충돌할 뻔했다.
  절차: 이슈 없이 PR 직행 / `[ci skip]`은 커밋이 아니라 **PR 제목**에 / 문서 변경은 CHANGELOG 대상 아님 / CLA·DCO 불필요 / 커밋 본문은 반드시 작성

**부수 실측** — Supabase 버킷의 파일 크기 제한(20MB)은 S3 프로토콜 경로에서도 적용된다. 21MB 업로드 시 `Aws::S3::Errors::EntityTooLarge`. 직접 업로드로 큰 파일이 들어와도 스토리지 층에서 막힌다는 뜻이라, 앱 검증이 사후에 도는 구조의 빈틈을 메워준다.

