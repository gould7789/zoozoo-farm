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
- **상류 이슈 검색 결과**:
  - PR #50781 (merged) — Kredis에서 `AS::Cache`로 옮긴 PR. DHH 본인이
    *"Problem with this in testing is that we default to `null_store`. So the value doesn't persist. So you can't test it."* 라고 지적했고,
    같은 스레드에서 "rate_limit 문서에 적어두자"는 제안까지 나왔으나 반영되지 않음
  - Issue #53172 (closed, `more-information-needed`) — memory_store로 바꿨을 때 카운터가 예제 간 누수되는 짝 문제
  - Issue #52823 — `ActionController::API`에 `cache_store`가 없어 rate limit이 동작하지 않는 별건
  - **edge `main`의 rdoc 확인 — 여전히 언급 없음**
- **적용한 우회**: `7204b89` — test 환경 `cache_store`를 `:memory_store`로 교체 + `spec/rails_helper.rb`에 `Rails.cache.clear` before 훅 (#53172 대응)
- **판정**: **상류 버그 아님.** 상류가 인지했으나 미해결로 남은 문서 공백. fail-open 자체는 의도된 설계라 코드 변경 제안은 채택 가능성이 낮다
- **다음 액션**: `rate_limiting.rb` rdoc에 한 문단을 더하는 문서 PR. 초안은 `docs/upstream-pr-rate-limit-docs.md`

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