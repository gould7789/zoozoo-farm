---
paths:
  - "app/controllers/application_controller.rb"
  - "app/controllers/animals_controller.rb"
  - "app/controllers/health_records_controller.rb"
  - "app/controllers/feeding_records_controller.rb"
  - "app/controllers/sales_records_controller.rb"
  - "app/controllers/expense_records_controller.rb"
---

# xlsx 내보내기 — 5개 컨트롤러가 같은 모양을 쓴다

## 왜 xlsx 인가

**감사 대응 때문이다.** 동물원은 CITES 서류와 지출 증빙을 요구받는다. 받는 쪽이 엑셀을 열어 정렬하고 합계를 내므로, PDF 나 CSV 가 아니라 **xlsx 여야 한다.**

현장 데스크톱은 전부 Windows + Excel 이다. 서식이 Excel 에서 어떻게 보이는지가 기준이다.

## 공유하는 것과 나누는 것

| 어디 | 무엇 |
| --- | --- |
| `ApplicationController#xlsx_styles` | 셀 스타일 7종 — 5개 컨트롤러가 전부 쓴다 |
| 각 컨트롤러의 `*_xlsx` | 열 이름, `row_styles` 배열, 열 폭 |

스타일만 올린 이유는, **열 구성은 도메인마다 다르지만 「날짜는 이렇게 보인다」는 공통**이기 때문이다. 한쪽만 바뀌면 파일 사이 모양이 어긋난다.

## Excel 에서만 드러나는 것

| 처리 | 안 하면 |
| --- | --- |
| `format_code: "yyyy-mm-dd"` | 날짜가 시리얼 숫자(`46234`)로 보인다 |
| `format_code: "#,##0"` | 금액에 자리 구분이 없어 자릿수를 세야 한다 |
| `sheet.column_widths` | 폭이 좁으면 Excel 이 **`####`** 로 가린다. 값이 있는데 없는 것처럼 보인다 |
| `pane.state = :frozen` + `y_split = 1` | 아래로 내리면 어느 열인지 모른다 |
| `auto_filter` | 받는 쪽이 정렬·필터를 직접 걸 수 없다 |

**`####` 는 데이터 문제가 아니라 폭 문제다.** 열을 늘리면 반드시 폭도 같이 넣는다.

## 정렬

자유 기술 칸(특이사항·상세 내용)만 `:left`, 나머지는 `:center`, 금액은 `:right`.

금액을 오른쪽으로 두는 이유는 **자릿수가 위아래로 맞아야 눈으로 비교되기** 때문이다.

## 동물 목록의 분류 칸

같은 카테고리가 이어지는 행은 분류명을 **비워 둔다.** 종이로 뽑았을 때 같은 값이 반복되면 어디서 끊기는지 안 보인다.

```ruby
category_cell = current_category == last_category ? nil : current_category
```

## 내보내기는 전용 액션이다 — `index` 에 얹지 않는다

처음에는 다섯 곳 모두 `index` 의 `respond_to` 안에 있었다. **세 가지가 거기서 나왔다.**

**권한 검사가 두 방식으로 갈렸다.** 매출·지출은 `before_action`, 건강·먹이는 **블록 안의 `return`** 이었다.

```ruby
format.xlsx do
  return redirect_to root_path, alert: "권한이 없습니다." unless current_user.admin?
```

이 `return` 은 **블록을 감싼 액션에서 빠져나오는 것**에 의존한다. 실측하면 멈춘다(Staff 302 / 0 bytes). 보안 결함은 아니었다. 문제는 선언적이지 않은 것이다 — **`before_action` 목록만 읽으면 권한이 없는 액션처럼 보인다.**

**차단 응답의 Content-Type 이 어긋났다.** `respond_to` 는 **블록 실행 전에 포맷을 확정**하므로, 블록 안에서 리다이렉트하면 302 인데 Content-Type 이 xlsx 다.

**`animals#index` 는 index 가 아니었다.** xlsx 전용이고 HTML 은 관 상세로 돌려보냈다. 동물 목록 화면은 `zones#show` 의 아코디언이라 별도 목록 페이지가 없다. **라우트가 사실을 말하지 않는다.**

```ruby
collection do
  get :export
end
```

`/sales/export` 가 `show` 의 `:id = "export"` 로 먹히지 않는다 — **collection 라우트가 기본 7개보다 먼저 생성된다.** `recognize_path` 로 확인했다(`matches?` 는 경로 패턴을 안 보므로 눈금이 못 된다).

`animals` 는 `except: [ :index ]` 다. **`zone_animals_path` 헬퍼는 남는다** — `create` 가 같은 경로를 POST 로 쓴다.

### 구 URL 은 살리지 않았다

`GET /sales.xlsx` 는 **406**, `GET /zones/1/animals` 는 **404** 다.

링크는 `⋯` 메뉴에서 페이지를 열 때마다 새로 생성되고, 받은 파일은 이미 PC 에 있다. 그리고 **URL 을 살려도 보안상 얻는 것이 없다** — `require_login` 이 비로그인을 어차피 막는다. 리다이렉트로 살리면 `index` 에 `respond_to` 가 남아 목적이 반만 달성된다.

### 확장자를 지우면 Turbo 가 링크를 가로챈다

**이것이 리팩토링이 만든 유일한 회귀였다.** 구 URL 은 `.xlsx` 로 끝났고 그 확장자가
Turbo 의 `unvisitableExtensions` 에 들어 있어 **그냥 통과**했다. 확장자가 사라진
`/sales/export` 는 방문 대상이 되어 Turbo 가 `Accept: text/html` 로 가져오고,
스프레드시트 Content-Type 을 받아 자기 검사에 실패한 뒤 `window.location.href` 로 떨어진다.

```
실측 — 링크 한 번 클릭
  data-turbo 없음   SalesRecordsController#export × 2
  data-turbo="false" SalesRecordsController#export × 1
```

**파일은 정상으로 받아진다.** 조용히 두 배로 드는 쪽이라 눌러봐도 모른다 —
쿼리와 caxlsx 렌더가 두 번 돈다. 그래서 다섯 링크 전부에 `data: { turbo: false }` 를 붙인다.

> `process_action.action_controller` 알림을 구독해 실제 호출 횟수를 셌다.
> 다운로드는 화면에 아무 변화를 주지 않으므로 **화면으로는 잴 수 없다.**

### 매출·지출은 연월을 받는다

화면의 Excel 링크가 `year` · `month` 를 함께 넘긴다. **안 넘기면 어느 달을 보고 있든 최신 월이 나와** 받은 파일과 화면이 어긋난다.

## 스펙은 5경로를 한 파일에 둔다

`spec/requests/xlsx_exports_spec.rb` 하나다. **컨트롤러 하나에서 `require_admin` 이 빠지면 에러 없이 Staff 에게 파일이 간다** — 표로 두면 빠진 줄이 눈에 보인다.

뷰의 경로 헬퍼 오타는 따로 안 덮었다. 5개 index 화면을 Admin 으로 렌더하는 요청 스펙이 이미 있어 **템플릿 에러로 시끄럽게 떨어진다.**
