# 헤더의 동작 버튼 — 「⋯」 로 접는 규칙

## 무엇이 깨졌었나

모바일 375px 에서 **관 상세의 관 이름이 통째로 사라졌다.**

```
화면          제목 폭 / 필요
관 상세          0px / 121px  << 사라짐
매출 기록       74px /  74px
공지 목록       74px /  74px
```

헤더가 `flex justify-between` 한 줄이고 왼쪽은 `min-w-0 truncate`, 오른쪽 버튼 3개는 `shrink-0` 이다.
`Excel` · `카테고리 관리` · `추가` 가 폭을 다 먹어 제목이 **0px 로 수축했다.**

> **겹침도 가로 스크롤도 아니다.** `truncate` 는 넘치는 대신 줄어들므로 두 검출 모두 0건을 냈다.
> 스크린샷을 보고 알았다. 제목이 다 보이는지는 `scrollWidth <= 실제 폭` 으로 따로 봐야 한다.

Staff 에게는 버튼이 없어 멀쩡하다 — **Admin 전용 결함이었다.**

## 규칙

```
주 동작 하나(추가·등록·작성)는 항상 밖에 둔다
보조 동작은 전부 ⋯ 안으로 접는다
```

| 화면 | 밖 | `⋯` 안 |
| --- | --- | --- |
| 관 상세 | `추가` | Excel · 카테고리 관리 |
| 매출 · 지출 · 건강 · 먹이 | `등록`·`추가` | Excel |
| 공지 목록 · 직원 관리 | `작성`·`추가` | — (보조 동작이 없다) |

**폭이 모자란 건 관 상세뿐인데도 다섯 화면을 같은 모양으로 맞췄다.** 한 화면만 다른 규칙이면
다음에 버튼을 더할 때 어느 쪽을 따를지 알 수 없다. 컴포넌트가 하나라는 것 자체가 규칙이다.

## `role="menu"` 를 쓰지 않는다

WAI-ARIA 는 그 역할에 **화살표 키 이동**을 요구한다. 여기 담기는 것은 보조 동작 한둘이라
Tab 으로 충분하고, 역할만 붙이고 키 이동을 안 만들면 **「있다고 한 조작이 안 되는」** 상태가 된다.
`aria-expanded` 를 가진 버튼이 패널을 여는 **disclosure** 로 둔다.

## `backdrop-blur` 가 패널을 가둔다

헤더 카드가 `bg-white/80 backdrop-blur-sm` 이다. **`backdrop-filter` 는 쌓임 맥락을 만든다** —
패널에 `z-20` 을 줘도 카드 밖으로 못 나가서 **뒤의 검색창 밑에 깔렸다.**

```erb
<div class="relative z-30 flex items-center justify-between ... backdrop-blur-sm ...">
```

**카드째 올려야 한다.** 같은 함정이 `common/views.md` 의 「모달은 body 직하에」와 뿌리가 같다.

> 이 결함은 **자동 테스트가 못 잡았다.** `have_link("Excel")` 은 CSS 상 visible 이면
> 덮여 있어도 통과한다. 스크린샷으로만 드러났다.

## 닫을 때 포커스를 버튼으로 돌린다

안 돌리면 사라진 요소에 포커스가 남아 **다음 Tab 이 문서 맨 앞으로 튄다.**
`document.activeElement` 가 메뉴 안에 있을 때만 옮긴다 — 바깥을 눌러 닫은 경우까지
포커스를 뺏으면 방금 누른 곳에서 초점이 달아난다.

## 어느 코드

| 파일 | 역할 |
| --- | --- |
| `app/javascript/controllers/menu_controller.js` | 열고 닫기, 바깥 클릭·ESC |
| `app/views/shared/_action_menu.html.erb` | 메뉴 껍데기. 항목은 블록으로 받는다 |
| `app/views/shared/_excel_icon.html.erb` | 5개 화면이 같은 SVG 를 쓴다 |
| `ApplicationHelper#menu_item_class` | 항목 클래스. 링크와 버튼이 같은 모양이어야 한다 |
| `spec/system/mobile_layout_spec.rb` | 375px 회귀. CDP 로 뷰포트를 덮어쓴다 |
