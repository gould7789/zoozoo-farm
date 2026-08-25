# rails/rails 문서 PR — 제출 완료

**[rails/rails#58558](https://github.com/rails/rails/pull/58558)** — 2026-08-25 제출, 리뷰 대기.

`docs/oss-candidates.md`의 「[2026-08-07] actionpack 8.1.3.1」 항목의 **다음 액션**을 실행한 결과.
이 저장소의 첫 오픈소스 기여다.

---

## 최종 제출 내용

`actionpack/lib/action_controller/metal/rate_limiting.rb`, 주석 5줄 추가 (`+6 -0`).

```diff
       # datastore as your general caches, you can pass a custom store in the `store`
       # parameter.
       #
+      # The limit is only enforced when the store's `increment` returns the updated
+      # count. Stores that don't count return `nil` instead, which silently turns
+      # `rate_limit` into a no-op. That includes `ActiveSupport::Cache::NullStore`,
+      # the default in the generated test environment, and any store that fails open
+      # while its backend is unavailable.
+      #
       # If you want to use multiple rate limits per controller, you need to give each of
       # them an explicit name via the `name:` option.
```

- 커밋: `dd9c91cde8` — `Document that rate_limit needs a counting store`
- PR 제목에 `[ci skip]` (기여 가이드 142행 — 커밋 메시지가 아니라 **PR 제목**에 넣는다)
- CHANGELOG 미작성 (가이드 618행 — 문서 변경은 대상 아님)
- Rails는 CLA·DCO 서명을 요구하지 않는다

## 왜 코드가 아니라 문서인가

`count && count > to`의 nil 스킵은 `d839ddb`(2024-01-17) 이후 한 번도 바뀌지 않았다.
캐시 장애 시 전원이 잠기는 것보다 통과시키는 쪽을 고른, 의도된 fail-open으로 읽는 게 타당하다.

게다가 상류는 이미 대안을 검토하고 기각했다 — byroot가 `NullStore` 감지를 *"too brittle"* 이라 했고,
대신 test 환경 기본값을 `MemoryStore`로 바꾸자는 쪽으로 합의했다. 그 합의가 2년 반째 미구현이다.

따라서 **이미 논의되고 기각된 것을 다시 제안하지 않는다.** 대신 PR 본문 말미에 이렇게 남겼다.

> **If you'd rather have the default changed as described above, I'm happy to attempt that
> instead and close this.**

메인테이너가 "문서 말고 기본값을 고쳐라"라고 하면 자연스럽게 더 큰 기여로 이어진다.

## 초안에서 실제 제출본으로 가며 바뀐 것

### ① 없는 인용을 걸러냈다

초안에는 *"같은 스레드에서 문서화 제안이 나왔다"* 고 적혀 있었다. **그런 코멘트는 존재하지 않았다.**
웹 검색 요약이 만들어낸 문장이었고, GitHub API로 코멘트 11개를 전부 대조해서 걸러냈다.

대신 실제 발언 3개를 문자 단위로 검증해 인용했다(dhh ×2, byroot ×1).

### ② 기존 문서와 충돌하는 문장을 뺐다

초안의 마지막 문장이 이랬다.

> To exercise rate limits in tests, set `config.cache_store = :memory_store` in
> `config/environments/test.rb` and clear it between tests.

그런데 rdoc 말미에는 **이미 테스트 조언이 있었고**, `60d92e4`(2026-01-02, zzak)가
바로 그 전역 설정 권고를 **의도적으로 제거**한 상태였다(커밋 제목: "to avoid global cache_store change").
즉 8개월 전 결정을 되돌리는 문장이었다.

rdoc 상단만 읽고 Examples 아래를 보지 않아서 생긴 일이고, **빌드된 문서 프리뷰를 눈으로 확인해서 잡았다.**
그 문장을 들어내니 오히려 남은 문단이 기존 조언의 **이유를 설명하는 위치**가 됐다.

## 확인한 것

| 주장 | 검증 방법 |
| --- | --- |
| `count &&` 가드가 `d839ddb`에서 도입 | `git log -S "count && count > to"` — 해당 커밋 단 하나 |
| 그 이후 가드 미변경 | 위와 동일. `store.increment` 줄은 캐시 키 인자가 2회 변경됨 |
| `NullStore#increment`가 빈 메서드 | `active_support/cache/null_store.rb` |
| 생성 템플릿이 `:null_store` | `test.rb.tt:27` |
| 인용문 3개 | GitHub API 응답과 문자 단위 대조 |
| 렌더링 | `buildkite/docs-preview` 통과 후 육안 확인 |

## 리뷰 대응 준비

> "Stores that don't count return `nil` instead"

엄밀히는 `ActiveSupport::Cache::Store#increment` 기본 구현이 `NotImplementedError`를 던진다
(`activesupport/lib/active_support/cache.rb:741`). nil 경로는 `NullStore`와 fail-open하는 스토어다.
문장이 바로 뒤에 `NullStore`를 명시하고 있어 오독 여지는 적지만, 지적이 오면 이렇게 답한다.

> Good point -- the base `Store#increment` raises `NotImplementedError`, so the `nil`
> path is specifically `NullStore` and stores that fail open. Happy to reword to
> "Stores that return `nil` instead of a count -- `NullStore`, and any store failing
> open -- silently turn `rate_limit` into a no-op."

## 다음

- 리뷰 대기. 코멘트 없이 추가 수정하지 않는다 — 볼 때마다 diff가 달라지면 리뷰어가 번거롭다
- force-push는 리뷰가 붙기 전까지만. 붙은 뒤에는 커밋을 얹는다
