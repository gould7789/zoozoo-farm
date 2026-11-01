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

## HTML 요청은 어떻게 되나

`animals#index` 는 **xlsx 전용 액션**이다. HTML 로 들어오면 관 상세로 돌려보낸다 — 동물 목록 화면은 `zones#show` 의 아코디언이고, 별도 목록 페이지가 없다.
