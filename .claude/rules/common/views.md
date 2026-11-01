---
paths:
  - "app/views/**/*.erb"
  - "app/assets/**/*.css"
  - "app/javascript/**/*.js"
---

# 화면

## 모바일 우선

사육사가 **우리(Cage) 앞에서 스마트폰으로** 조작하는 것이 기준 시나리오다. 데스크톱은 사무실 Windows PC다.

- 터치 영역 최소 44px
- 입력창은 터치로 다루기 충분한 크기
- 좁은 폭에서 가로 스크롤이 생기지 않게

### 터치 영역과 시각적 무게는 분리한다

**44px를 지키려다 기능을 가린 적이 있다.** Trix 툴바 버튼을 전부 44px로 키우고 가로 스크롤을 걸었더니, 13개 중 뒤쪽 3개(첨부·실행취소·다시실행)가 화면 밖으로 밀려 **존재 자체를 알 수 없게** 됐다.

두 축은 따로 조절한다.

| 축 | 방법 |
| --- | --- |
| 터치 영역 | 버튼 박스 크기 |
| 시각적 무게 | 아이콘 크기(`::before`의 `inset`), 색, `opacity` |

**규칙은 수단이고, 확인은 화면에서 한다.** 요소가 DOM에 있다고 보이는 것이 아니다.

## 화면 텍스트는 한국어

notice·alert·버튼·링크·라벨·안내문 전부. 쓰는 사람이 한국 동물원 직원이다.

## CSP 제약

```ruby
default_src :self
script_src  :self + nonce      # 인라인 <script> 금지, CDN 금지
style_src   :self + nonce      # 인라인 <style> 금지
img_src     :self, :data, :blob
```

여기서 따라오는 것들.

| 하고 싶은 것 | 할 수 없는 이유 | 대신 |
| --- | --- | --- |
| CDN에서 JS 가져오기 | `script_src :self` | importmap에 vendor로 받기 |
| 인라인 `onclick` | `script_src` | Stimulus 컨트롤러 |
| 레이아웃에 인라인 `<style>` | `style_src` | Tailwind 소스로 이관 |
| `blob:` URL 미리보기 | `img_src`에 `:blob` 추가로 해결됨 | — |

**외부 오리진을 허용할 때는 경로를 붙이지 않는다.** CSP는 소스에 경로가 있고 끝이 `/`가 아니면 URL의 경로가 **완전히 같아야** 한다. 오리진(`scheme://host`)만 쓴다.

그리고 필요한 컨트롤러에만 붙인다. 전역에 두면 **비로그인으로 보이는 로그인 화면에까지** 외부 호스트명이 실린다.

```ruby
# app/controllers/notices_controller.rb
content_security_policy do |policy|
  policy.connect_src :self, *STORAGE_ORIGIN
end
```

> 개발·테스트는 Disk 서비스라 동일 오리진이어서 **CSP 문제가 재현되지 않는다.** 운영에서만 터진다.

## 모달과 다이얼로그는 body 바로 아래에 둔다

`fixed` 는 **뷰포트 기준으로 동작해야** 화면 가운데에 온다. 조상에 `transform` · `filter` · `contain` 이 걸려 있으면 그 요소가 기준이 되어 엉뚱한 자리에 뜬다. 레이아웃 안쪽에 두면 언제 그렇게 될지 알 수 없으므로 **`body` 직하에 렌더한다.**

```erb
<%# layouts/application.html.erb 의 끝, zones/show.html.erb 의 끝 %>
<%= yield :modals %>
```

모달이 `body` 직하에 있고 조작하는 버튼이 본문에 있으면, Stimulus 는 **Outlet** 으로 잇는다.

### `window.confirm()` 대신 `<dialog>`

브라우저 표준 `<dialog>` 에는 **포커스 트랩·ESC·백드롭이 이미 들어 있다.** 직접 만들지 않는다. `showModal()` 은 top layer 에 올리므로 조상의 `z-index` 와 `overflow` 에 영향받지 않는다.

`form method="dialog"` 는 누른 `button` 의 `value` 를 `returnValue` 에 넣고 닫는다 — 어느 버튼을 눌렀는지 JS 없이 알 수 있다.

**두 가지가 Tailwind 와 부딪힌다.**

| 함정 | 왜 |
| --- | --- |
| `m-auto` 를 꼭 넣는다 | `dialog:modal` 은 `inset: 0 + margin: auto` 로 가운데 오는데, preflight 의 `* { margin: 0 }` 이 덮어써서 **왼쪽 위에 붙는다** |
| `padding` 은 안쪽 `form` 에 준다 | `dialog` 자신에 주면 그 영역이 백드롭으로 판정돼 **안을 눌러도 닫힌다** |

## `button_to` 의 폼에 `display: contents`

`button_to` 는 `<form>` 을 만들고 그 안에 `<button>` 을 넣는다. 그래서 **`<form>` 이 flex 아이템이 되고 `<button>` 은 손이 닿지 않는 자식**이 된다. 옆의 링크와 세로가 어긋나거나 `gap` 이 먹지 않는다.

```erb
<%= button_to "삭제", path, method: :delete,
    form: { class: "contents" },        <%# 폼을 레이아웃에서 투명하게 만든다 %>
    class: "text-xs text-red-400" %>
```

`display: contents` 는 그 요소의 박스를 없애고 **자식을 부모의 직접 자식처럼** 배치시킨다. `<button>` 이 그대로 flex 아이템이 된다.

`inline` 으로 두면 폼 안에 행 박스가 생기고, `inline-block` 인 `<button>` 이 베이스라인에 올라 **디센더만큼 키가 커져** 옆 요소와 몇 px 어긋난다. 보고 알아채기 어려운 종류다.

**앱에서 11곳이 이 형태다.** `button_to` 를 flex 안에 넣을 때는 늘 같이 붙인다.

> 폼 안에 또 `<form>` 을 넣을 수는 없으므로, **이미 폼 안인 자리에서는 `button_to` 를 쓰지 않는다.** `link_to` + `turbo_method` 를 쓴다 — Turbo 가 누를 때 `body` 직하에 폼을 만든다 (`animals/_form.html.erb`).

## Stimulus

- 파일명 `foo_controller.js` → `data-controller="foo"`
- `data-action="event->foo#method"`
- 타깃은 `data-foo-target="name"`

라이브러리의 이벤트를 가로챌 때는 **그 리스너가 어디에 등록돼 있는지 먼저 소스로 확인한다.** `window`에 등록돼 있으면 요소 리스너가 먼저 잡으므로 `stopPropagation()`으로 막을 수 있지만, 요소에 직접 등록돼 있으면 그 방법이 성립하지 않는다.

## Tailwind

엔트리는 `app/assets/tailwind/application.css` 하나다. `stylesheet_link_tag :app`은 Propshaft가 로드 패스의 **스타일시트를 전부** 링크하므로, 거기에 `@import`를 또 쓰면 같은 파일이 두 번 실린다.

gem이 제공하는 CSS를 덮을 때는 **명시도를 맞춰야 한다.** 예를 들어 `actiontext.css`는 `.trix-content .attachment-gallery.attachment-gallery--2 .attachment`(0,4,0)로 잡고 있어서, 더 낮은 명시도로 쓰면 적용되지 않는다. **세로로 쌓였다고 다 된 것이 아니라 폭까지 확인한다.**

## 배경

배경 이미지는 `body`가 아니라 **화면에 고정한 의사 요소**에 그린다. `body`에 `bg-cover`를 주면 입력창이 늘어날 때마다 `cover`가 배경을 확대한다.

```css
.zoo-bg::before { position: fixed; inset: 0; z-index: -1; background-size: cover; }
```
