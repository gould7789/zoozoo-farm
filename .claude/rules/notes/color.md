# 색 — 회색 3단계와 빨강의 자리

## 텍스트 회색은 3단계뿐이다

```
gray-900   제목 · 강조        text-xl / 굵은 text-sm
gray-700   본문               text-sm
gray-500   라벨 · 보조 텍스트   text-xs / 굵은 라벨
```

**`300` · `400` · `600` · `800` 은 쓰지 않는다.** `spec/lint/color_discipline_spec.rb` 가 막는다.

### 왜 7단계였나

도입 때 역할을 안 정하고 그때그때 골랐다. 실측하면 이렇게 보였다.

```
          text-xl  text-sm  text-xs  굵게   합계
gray-900     26       25       ·      45     68   제목 — 확고했다
gray-700      ·       74       ·       4     93   본문 — 확고했다
gray-500      1       14      50      46    102   두 역할 혼재
gray-400      ·       17      60       6     97   500 과 같은 자리
```

`900` 과 `700` 은 **이미 역할이 분명**했다. 문제는 `500` 이 **굵은 테이블 헤더·섹션 라벨(46건)과 평범한 보조 텍스트(50건)를 겸한 것**, 그리고 `400` 이 같은 자리를 나눠 쓴 것이었다.

**`500` 과 `400` 을 합쳐도 되는 이유** — 라벨은 이미 `font-semibold uppercase tracking-wider` 로
구분된다. **굵기와 자간이 하는 일을 색이 또 할 필요가 없다.**

`hover:` 쌍도 하나로 모인다.

```
text-gray-500 hover:text-gray-700    ← 이 하나만 쓴다
```

## 테두리와 배경은 건드리지 않았다

이미 규칙이 있었다. **역할로 갈려 있으므로 줄이면 안 된다.**

```
border-gray-200   카드 46        border-gray-300   입력창 47
bg-gray-50  54    bg-gray-100  16
```

## 빨강은 「되돌릴 수 없는 것」에 쓴다

도입 때 **red 94 > green 69** 였다. 브랜드색보다 많았고 10단계를 전부 썼다.
목록 행마다 「삭제」가 빨강이라, 정작 **내보내기·완전 삭제가 묻혔다.**

### 레퍼런스

**GOV.UK Design System**

> "Only use warning buttons for actions with serious destructive consequences that cannot be easily undone."
> "Warning buttons only work if used very sparingly. Most services should not need one."
> "Do not only rely on the red colour of a warning button to communicate the serious nature of the action."
> 확인 단계가 있으면 **"use another style of button for the initial call to action, and a warning button for the final confirmation."**

**Shopify Polaris**

> "only use a red button for an action that's difficult or impossible to undo"

다만 **`plain destructive`**(채운 버튼이 아니라 빨강 글자만)를 따로 두고 「카드 안의 Remove
같은 작은 삭제」용이라고 명시한다.

### 그래서 어디에 쓰나

| 자리 | 어떻게 | 왜 |
| --- | --- | --- |
| 내보내기 · 완전 삭제 | `bg-red-500` / `bg-red-600` **채운다** | 되돌릴 수 없다 |
| 확인 다이얼로그의 「확인」 | `bg-red-600` **채운다** | GOV.UK 의 final confirmation |
| 목록 행의 삭제 | **빨강 글자만** | Polaris 의 plain destructive. 확인 다이얼로그가 따로 있다 |
| 에러 박스 | `bg-red-50` + `text-red-700` | 버튼이 아니라 상태 표시 |
| **안내 다이얼로그의 「확인」** | **중립색(`bg-gray-700`)** | 아무 일도 일어나지 않는다 |

**색이 유일한 단서가 아니다.** 모든 삭제에 「삭제」라는 글자와 확인 다이얼로그가 있다 —
색맹 사용자에게도 전달된다. 그래서 글자색의 빨강은 **빼지 않고 남겼다.**

### 안내 다이얼로그가 빨강이었던 것은 버그였다

`confirm_dialog_controller#notify` 는 취소를 숨기고 「확인」만 남긴다
(`blocked_delete_controller` 가 「기록이 있는 계정은 지울 수 없다」를 띄우는 자리).
**누르면 그냥 닫히는데 버튼이 `bg-red-600` 이었다.** 위험한 것을 승인하는 것처럼 보인다.

`cancellable` 로 이미 두 모드를 구분하고 있어서 **거기에 색을 묶었다.**

> 클래스를 JS 에서 토글하므로 **Tailwind 가 그 클래스를 찾아내는지 확인해야 한다.**
> 빌드 산출물에서 `bg-gray-700` · `hover:bg-gray-800` 이 실제로 나오는 것을 보고 넣었다.

## 지출 화면의 빨강은 그대로 둔다

연도 칩이 `bg-red-500` 이고 매출은 `bg-blue-600` 이다. 사고가 아니라
**매출/지출을 색으로 가른 의도**이고 회계 관습(지출=빨강)에 맞는다.

## `@theme` 의미 토큰을 안 쓴다

`text-ink` · `text-muted` 같은 어휘를 세우는 안을 검토하고 버렸다.

1. 직원 10명 규모에 과하다
2. **컴포넌트 추출 없이는 값이 안 난다** — 주 동작 버튼 클래스가 17개 파일에 복붙돼 있어서,
   토큰만 세우면 그 복붙이 유지된 채 이름만 바뀐다

컴포넌트를 뽑게 되면 그때 같이 본다.

## 색은 테스트가 못 잡는다

동작이 안 바뀌므로 **system spec 이 전부 초록인 채로 화면이 이상해질 수 있다.** 둘로 덮었다.

| 수단 | 무엇을 잡나 |
| --- | --- |
| `spec/lint/color_discipline_spec.rb` | 폐기한 회색이 다시 들어오는 것 |
| `spec/system/confirm_dialog_spec.rb` | 두 모드의 버튼 색. **클래스가 아니라 계산된 색**을 본다 |
| 전후 스크린샷 | 나머지 전부. 사람이 본다 |

가운데가 중요하다 — 클래스명으로 단언하면 **그 클래스가 빌드된 CSS 에 없어도 통과**한다.
기대값도 문자열로 박지 않는다. Tailwind v4 는 `oklch` 로 내므로, **그 클래스를 실제로
칠한 요소에서 값을 읽어** 비교한다.
