---
paths:
  - "spec/**/*.rb"
---

# 테스트

## TDD 순서를 지킨다

```
① spec 작성 → ② 실행해서 Red 확인 → ③ 구현 → ④ 실행해서 Green 확인
```

버그 수정이면 **재현 스펙을 먼저 쓰고 Red를 실제로 보여준 뒤** 고친다.

## 되돌리면 빨개지는지 확인한다

**이게 가장 중요하다.** 초록은 검증의 증거가 아니다.

```
수정을 되돌린다 → 테스트가 빨개지는가?
  빨개진다  → 그 테스트는 그 수정을 검증하고 있다
  통과한다  → 아무것도 검증하지 않는 테스트다
```

실제로 한 작업에서 **측정 대상을 세 번 잘못 골랐다.** 전부 코드가 아니라 눈금이 틀린 경우였다.

| 틀린 측정 | 무슨 일이 있었나 |
| --- | --- |
| `<<~SQL.squish` | 스펙 헬퍼가 테스트 데이터를 망가뜨려 **검증 대상 자체가 사라졌다** |
| `create_and_upload!(content_type:)` | Active Storage가 실제 바이트로 재판정해 위장이 안 됐다 |
| `content.embeds.size == 1` | 두 번 올라가도 sgid는 하나만 남아 이중 업로드를 못 잡았다 |

> 측정이 예상과 다르면 **코드가 틀렸다고 생각하기 전에 내가 맞는 것을 재고 있는지 의심한다.**

## 성능 검증과 표시 검증은 다른 축이다

N+1 스펙은 **쿼리 수만** 본다. 쿼리를 줄이려고 바꾼 코드가 화면 결과를 망가뜨려도 초록이다. 둘 다 필요하다.

## 환경을 재현해서 Red를 만든다

로컬에서만 통과하는 테스트는 의미가 없다.

```bash
TZ=UTC bundle exec rspec        # 로컬 KST, 서버 UTC
```

## 검증이 실제로 문제 경로를 지나는지

통과하는 명령을 믿기 전에 **고치기 전에도 통과했을지** 따진다.

- `bin/rails -v`는 앱을 부팅하지 않는다
- `bundle exec brakeman`에는 `bin/brakeman`이 주입하는 `--ensure-latest`가 없다

## 구성

| gem | 역할 |
| --- | --- |
| `rspec-rails` | 프레임워크 |
| `factory_bot_rails` | 테스트 데이터 |
| `faker` | 가짜 값 |
| `shoulda-matchers` | 검증 헬퍼 |

```
spec/
├── models/       유효성, enum, 스코프
├── requests/     인증·권한 분기, N+1
├── migrations/   운영 DB를 바꾸는 마이그레이션
├── system/       화면 상태 전이 (Capybara + Selenium)
├── factories/
└── support/
```

테스트 코드 내 문자열은 현재 **일본어**다 (`domain.md`의 전환 메모 참조).

## system spec

Selenium의 좌표 클릭이 이 구성(Turbo + Stimulus)에서 **1~2할 확률로 핸들러에 도달하지 않는다.** 실측으로 확인했고, 대기 시간을 늘려도 실패율이 같았다 — 지연이 아니라 유실이다.

`spec/support/system_helpers.rb`의 `click_reliably` / `fill_in_reliably`를 쓴다.

대기는 `page.all`이 아니라 `have_css` / `have_no_css`를 쓴다. `page.all`은 **재시도 없이 즉시 반환**해서 느린 CI에서 깨진다.

## CI와 같은 명령으로 돌린다

`bundle exec`로 바꿔 돌리지 않는다. `bin/` 래퍼가 플래그를 주입한다. 명령은 `.github/workflows/ci.yml`에서 복사해 온다.
