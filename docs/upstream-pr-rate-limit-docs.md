# rails/rails 문서 PR 초안 — rate_limit의 fail-open 명시

`docs/oss-candidates.md`의 「[2026-08-07] actionpack 8.1.3.1」 항목의 **다음 액션**을 실행하기 위한 초안.
제출은 수동으로 한다.

---

## 왜 코드가 아니라 문서인가

`count && count > to`의 nil 스킵은 v7.2.0(기능 최초 도입)부터 지금까지 그대로다.
캐시가 죽었을 때 전원이 잠기는 것보다 통과시키는 쪽을 고른, 의도된 fail-open으로 읽는 게 타당하다.
따라서 "nil이면 예외를 던지자" 류의 동작 변경 제안은 **채택되지 않을 가능성이 높고, 제안하지 않는다.**

반면 그 동작이 문서에 한 줄도 없다는 것은 명백한 공백이다.
게다가 상류가 이미 이 문제를 인지하고 문서화까지 제안했는데 반영되지 않은 상태다 — 근거를 인용할 수 있다.

## 대상

`actionpack/lib/action_controller/metal/rate_limiting.rb` 의 `rate_limit` rdoc.
"Rate limiting relies on a backing `ActiveSupport::Cache` store..." 문단 바로 뒤에 한 문단을 넣는다.

## 제안 diff

```diff
       # Rate limiting relies on a backing `ActiveSupport::Cache` store and defaults to
       # `config.action_controller.cache_store`, which itself defaults to the global
       # `config.cache_store`. If you don't want to store rate limits in the same
       # datastore as your general caches, you can pass a custom store in the `store`
       # parameter.
       #
+      # The limit is only enforced when the store's `increment` returns the updated
+      # count. A store that does not count -- most notably `:null_store`, which is the
+      # default in the test environment -- silently turns `rate_limit` into a no-op, and
+      # so does a store that fails open while its backend is unavailable. To exercise
+      # rate limits in tests, set `config.cache_store = :memory_store` in
+      # `config/environments/test.rb` and clear it between examples.
+      #
       # If you want to use multiple rate limits per controller, you need to give each of
       # them an explicit name via the `name:` option.
```

## PR 제목

```
Document that rate_limit is a no-op when the store cannot count
```

## PR 본문

````markdown
### Summary

`rate_limit` only enforces the limit when the backing store's `increment` returns the
updated count:

```ruby
count = store.increment(cache_key, 1, expires_in: within)
if count && count > to
```

The `count &&` guard means a store that returns `nil` disables rate limiting entirely --
no exception, no warning, no log line. `ActiveSupport::Cache::NullStore#increment` is an
empty method, so `rate_limit` is a no-op under the cache store that `rails new` generates
for the test environment.

This is not a new observation. In #50781, which introduced the current
`ActiveSupport::Cache`-backed implementation, @dhh noted:

> Problem with this in testing is that we default to `null_store`. So the value doesn't
> persist. So you can't test it.

and the thread suggested mentioning it in the `rate_limit` docs. That never landed, and
the rdoc still doesn't say it. #53172 is the mirror problem people hit right after
switching to `:memory_store`.

The failure mode is easy to hit and hard to notice, because the natural test -- "the 11th
request is blocked" -- passes trivially when the limiter is off in the opposite direction:
it never blocks anything, so a suite that only asserts on *unlimited* requests stays green
while the protection is gone.

### What this changes

Documentation only -- one paragraph in the `rate_limit` rdoc. No behavior change.

The fail-open itself looks deliberate (a cache outage locking every user out is worse than
letting requests through), so this PR does not propose changing it -- only writing it down,
along with the one-line fix for testing.
````

## 제출 전 확인

- [ ] `main` 최신 기준으로 해당 rdoc 문단이 아직 그대로인지 재확인
- [ ] 인용한 #50781 코멘트 문구가 원문과 정확히 일치하는지 대조
- [ ] rails/rails의 `CONTRIBUTING.md` — 문서 전용 PR은 `[ci skip]`을 커밋 메시지에 넣는 관례가 있는지 확인
- [ ] guides(`guides/source/`)에도 같은 내용을 넣을지 판단. 우선 rdoc만으로 제출하고 리뷰어 요청이 있으면 추가
