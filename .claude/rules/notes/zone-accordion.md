---
paths:
  - "app/views/zones/**/*.erb"
  - "app/views/animal_categories/**/*.erb"
  - "app/controllers/animal_categories_controller.rb"
  - "app/controllers/zones_controller.rb"
  - "app/javascript/controllers/search_controller.js"
  - "app/javascript/controllers/modal_controller.js"
  - "app/javascript/controllers/modal_opener_controller.js"
  - "app/javascript/controllers/category_row_controller.js"
---

# 관 상세의 아코디언과 카테고리 모달

## 화면 구조

```
/zones/:id
├─ 검색 필드 ┐
└─ 아코디언  ┘ ← search 컨트롤러가 둘을 함께 감싼다
   ├─ 카테고리 A (hidden: false 만)
   │  ├─ 모바일: _animal_card
   │  └─ 데스크톱: _animal_row  (table-fixed 5열)
   └─ 미분류 (animal_category_id 가 nil)

body 직하 ─ 카테고리 관리 모달 (Admin 전용)
```

**동물 목록 화면은 따로 없다.** `animals#index` 는 xlsx 전용이고, 목록은 이 아코디언이 전부다.

## 왜 partial 전체를 교체하나

카테고리를 추가·수정·숨김 토글하면 **아코디언 전체를 `turbo_stream` 으로 갈아끼운다.** 행 하나만 바꾸지 않는 이유는, 카테고리가 바뀌면 **그 아래 동물의 소속과 순서까지 바뀌기** 때문이다. 부분 갱신으로는 둘을 맞출 수 없다.

그래서 `create` · `update` · `toggle` 세 액션이 같은 데이터를 다시 모은다 — `load_accordion_data` 로 묶었다.

```ruby
# includes(:health_records) 가 없으면 아코디언이 latest_condition 을 부를 때 N+1 이 된다
@animals_by_category = @zone.animals.active
                            .includes(:health_records)
                            .with_attached_photo
                            .group_by(&:animal_category_id)
```

`group_by` 의 키가 `nil` 인 묶음이 **미분류**다. 별도 쿼리를 날리지 않는다.

## `replace` 와 `update`

```erb
turbo_stream.replace "category_row_#{id}", partial: "…"
```

**`update` 가 아니라 `replace` 다.** `update` 는 대상의 `innerHTML` 만 갈아끼우므로 partial 의 루트 `div` 가 **이중이 된다.** `padding` 이 겹쳐 그 행만 들여쓰기된 것처럼 보인다 — 에러가 아니라 레이아웃으로 드러나서 찾기 어려웠다.

반대로 **`id` 를 붙인 자리는 `replace` 대상이라는 뜻**이다. JS 는 그 `id` 를 참조하지 않는다.

## 모달이 열린 채로 뒤가 갱신된다

숨김 토글은 **모달을 닫지 않고** 뒤의 아코디언을 갱신한다. `turbo_stream` 이 두 자리를 한 응답으로 바꾼다.

| 바꾸는 것 | 왜 |
| --- | --- |
| 모달 안의 카테고리 목록 | 체크박스 상태와 순서 |
| 뒤의 아코디언 | 숨김 변경을 즉시 반영 |

모달이 `body` 직하라 본문의 버튼과는 **Outlet** 으로 잇는다. 이유는 `.claude/rules/common/views.md`.

## 관 목록의 표시 순서

`zones` 는 시드 고정이라 **이름 배열로 순서를 박아 정렬한다.** `id` 순에 맡기면 시드를 다시 심을 때 순서가 흔들린다.

## 사진이 없는 개체

`_animal_avatar` 는 사진이 없어도 **같은 크기의 틀을 낸다.** 안 그러면 행마다 글자 시작 위치가 어긋난다.

빈 자리에 사진 아이콘을 두면 「이미지가 깨졌다」로 읽히므로 **발바닥 모양**을 쓴다. `alt` 는 비워 둔다 — 옆에 종명과 개체명이 있어 읽기가 중복된다.
