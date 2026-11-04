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

`describe` · `it` 설명도 한국어로 쓴다. 테스트 출력이 그대로 읽히는 문장이 된다.

## system spec

Selenium의 좌표 클릭이 이 구성(Turbo + Stimulus)에서 **1~2할 확률로 핸들러에 도달하지 않는다.** 실측으로 확인했고, 대기 시간을 늘려도 실패율이 같았다 — 지연이 아니라 유실이다.

`spec/support/system_helpers.rb` 의 헬퍼를 쓴다.

| 헬퍼 | 무엇을 흡수하나 |
| --- | --- |
| `click_reliably` | 좌표를 거치지 않고 DOM 의 `click` 을 직접 일으킨다 |
| `fill_in_reliably` | `send_keys` 의 유실 — 값이 들어갔는지 **확인하고 다시 넣는다** |
| `click_in_dialog` | 결과가 나오고 **다이얼로그가 닫히기까지** 기다린다 |

**무엇을 포기하는지 알고 쓴다.** `click_reliably` 가 잃는 것은 브라우저의 당타 판정뿐이고, 실제 click 이벤트·핸들러·폼 전송은 그대로 지난다. 당타 판정은 이 spec 의 검증 대상이 아니라 사람이 눌러서 담보한다(`qa` 스킬).

`fill_in_reliably` 가 매번 `find_field` 를 다시 하는 이유는, 요소를 쥔 채 재시도하면 DOM 이 갈릴 때 `StaleElementReferenceError` 가 되어 **흡수하려던 것과 같은 모양으로 떨어지기** 때문이다.

빈 칸으로 전송되면 더 고약하다 — 로그인 폼은 두 항목이 `required` 라 **브라우저 검증이 전송 자체를 막는다.** 서버에 아무것도 닿지 않고 에러도 안 뜨므로, 뒤의 단언이 「요소를 못 찾았다」처럼 **원인과 무관한 모양**으로 실패한다.

`click_in_dialog` 가 닫힘까지 기다리는 이유는 모달이 열려 있는 동안 **뒤의 요소가 `inert`** 가 되어 그쪽 클릭이 무시되기 때문이다. 결과가 안 나온 채 닫혀 있으면 다시 눌러도 의미가 없다 — 닫힌 다이얼로그 안의 버튼은 찾히지 않아 대기 시간만 쓰고 `ElementNotFound` 가 된다.

대기는 `page.all` 이 아니라 `have_css` / `have_no_css` 를 쓴다. `page.all` 은 **재시도 없이 즉시 반환**해서 느린 CI 에서 깨진다.

### Trix 버튼은 click 으로 눌리지 않는다

`trix.js` 의 `ToolbarController` 는 서식·동작 버튼에 **`mousedown`** 을 건다(`handleEvent("mousedown", ...)`).
`click` 은 다이얼로그 버튼에만 쓴다. 그래서 `click_reliably` 도 `this.click()` 도 **그 핸들러에 영원히 닿지 않는다.**

```js
el.dispatchEvent(new MouseEvent("mousedown", { bubbles: true }))
```

실제로 「서식이 안 걸린다」로 보여 코드를 의심했지만 **눈금이 틀린 것**이었다. 선택 범위도 찍어보고
`editor.activateAttribute("italic")` 로는 걸리는 것을 확인한 뒤에야 이벤트 종류가 원인이라는 데 닿았다.

에디터에 **포커스를 주지 않으면** `setSelectedRange` 가 내부 값만 바꿔 서식이 아무 데도 안 걸린다.

### 모바일 폭은 screen_size 로 만들어지지 않는다

headless Chrome 은 **창 최소 폭이 500px** 이라 `screen_size: [375, 812]` 로 띄워도 `clientWidth` 가 500 이 된다.
그 상태로 「모바일에서 겹치는가」를 재면 **엉뚱한 결과가 나온다.**

```ruby
page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
  width: 375, height: 812, deviceScaleFactor: 2, mobile: true)
```

### 가로 넘침 검출은 truncate 를 못 본다

`min-w-0` + `truncate` 가 걸린 제목은 폭이 모자라면 **넘치지 않고 0px 로 수축한다.**
`scrollWidth > clientWidth` 도, 사각형 교차 검사도 **둘 다 0건**을 낸다. 글자가 다 보이는지는
`scrollWidth <= getBoundingClientRect().width` 로 따로 봐야 한다.

### 보이는 것과 위에 그려지는 것은 다르다

`have_link("Excel")` 은 CSS 상 visible 이면 통과한다. **다른 요소에 덮여 있어도 통과한다.**
조상에 `backdrop-filter` 가 걸리면 쌓임 맥락이 생겨 자식의 `z-index` 가 그 밖으로 못 나가는데,
그 결함은 **스크린샷으로만 드러났다.**

### 흔들리는 스펙은 환경 탓이 아닐 수 있다

`style/mobile-layout` 에서 예제 셋이 돌아가며 떨어졌다. **값을 20회 찍어보고서야** 갈렸다.

| 흔들림 | 정체 |
| --- | --- |
| 폭 단언 | `visit` 뒤에 뷰포트를 바꿔 재배치 경합 — **방문 전에 고정**한다 |
| 툴바 버튼이 가끔 없음 | **제품 버그.** `trix-initialize` 가 Stimulus 연결보다 먼저 나서 `data-action` 이 놓친다 |
| ESC 가 가끔 안 먹음 | Selenium 의 키 전달 유실 — `keydown` 을 DOM 에 직접 일으킨다 |

가운데가 중요하다. **「환경 탓」으로 넘겼으면 제품 버그를 그대로 배포했다.**
`connect()` 에서 이미 초기화됐는지(`element.editor`) 보고 직접 부르면 양쪽이 덮인다.

### 대기 시간은 5초다

기본 2초로는 부족하다. 브라우저 기동 → 로그인 → 업로드 → canvas 변환이 연달아 일어나므로, 부하가 높을 때 2초를 넘겨 **로그인 화면 그대로 판정**된 적이 있다. CI 러너는 로컬보다 느리다.

화면 크기는 `1400x900` — 현장의 주 사용 환경이 Windows 데스크톱이다.

## 전수 검사는 대상을 손으로 나열하지 않는다

주석을 한국어로 옮길 때 **같은 검사식을 네 번 고쳤다.**

| 회차 | 빠뜨린 것 |
| --- | --- |
| 1 | 한자만 있는 일본어 (가나만 봤다) |
| 2 | U+30FB 가타카나 중점 (범위가 `30FA` 까지였다) |
| 3 | `.github/` |
| 4 | 루트(`Gemfile` · `render.yaml` · `.gitignore`)와 `script/` |

**원인이 매번 같다 — 검사 대상을 디렉토리 목록으로 손수 나열했다.** 나열한 목록은 반드시 무언가를 빠뜨린다.

추적 파일 전체를 보려면 `git grep` 을 쓴다.

```bash
git grep -lP '[\x{3041}-\x{3096}\x{30A1}-\x{30FB}\x{4E00}-\x{9FFF}]' \
  -- . ':!README.md' ':!docs/' ':!*.png' ':!*.jpg' ':!*.heic'
```

`git grep` 은 **추적되는 파일을 전부** 보므로 새 디렉토리가 생겨도 자동으로 들어온다. 바이너리는 바이트열이 우연히 매칭되므로 pathspec 으로 뺀다.

## CI와 같은 명령으로 돌린다

`bundle exec`로 바꿔 돌리지 않는다. `bin/` 래퍼가 플래그를 주입한다. 명령은 `.github/workflows/ci.yml`에서 복사해 온다.
