---
paths:
  - "app/models/**/*.rb"
  - "app/controllers/**/*.rb"
---

# 모델과 컨트롤러

## Fat Model, Skinny Controller

비즈니스 로직은 모델에, 컨트롤러는 얇게.

```ruby
# app/models/health_record.rb
scope :danger, -> { where(condition: 2) }
scope :recent, -> { order(recorded_on: :desc) }

# app/controllers/health_records_controller.rb
def index
  @health_records = @animal.health_records.recent   # 컨트롤러는 얇게
end
```

## Service / DTO 폴더는 없다 — 의도적이다

| 폴더 | 안 만든 이유 |
| --- | --- |
| `app/services/` | CRUD 위주라 Controller/Model로 충분하다 |
| `app/dto/` | ERB 풀스택이라 API 모드가 아니다. JSON 응답 구조화가 불필요하다 |

**도입 시점을 정해뒀다.** 아래에 해당하면 그때 추출한다.

```
컨트롤러 액션이 50줄 이상
같은 로직이 3곳 이상 반복
외부 API 연동이 생길 때
```

조건에 안 맞는데 미리 만들지 않는다.

## 권한 체크 패턴

```ruby
before_action :require_login                  # 모든 액션
before_action :require_admin                  # Admin 전용
before_action -> { require_owner(@notice) },  only: [ :edit, :update, :destroy ]
```

본인 기록 확인은 `created_by_id == current_user.id`. Admin은 타인 기록도 조작할 수 있다.

> **`ApplicationController`를 상속하지 않는 컨트롤러는 이 보호를 받지 못한다.** Active Storage처럼 gem이 가져온 컨트롤러가 그렇다. gem을 추가하면 `rails routes`로 늘어난 라우트를 보고, 그게 우리 인증 안쪽인지 확인한다.

## 검증은 신뢰 경계에서 빼지 않는다

코드를 줄이려고 생략해도 되는 것과 아닌 것이 있다.

| 빼도 되는 것 | 빼면 안 되는 것 |
| --- | --- |
| 일어날 수 없는 상황의 에러 처리 | **신뢰 경계의 검증** |
| 단일 사용처의 추상화 | 데이터 손실을 막는 에러 처리 |
| 요청하지 않은 설정 가능성 | 보안, 접근성 |

**폼을 거치지 않고 들어오는 값이 신뢰 경계다.** 예를 들어 Action Text의 임베드 이미지는 다이렉트 업로드로 들어오므로 폼 검증을 통과하지 않는다. 모델에서 따로 막아야 한다.

## enum

```ruby
enum :condition, { normal: 0, caution: 1, danger: 2 }
enum :cites_grade, { none: 0, ... }, prefix: :cites   # AR의 none? 과 충돌하므로 prefix
```

컨트롤러에서 `params`로 받은 값을 그대로 `where(category: ...)`에 넘기지 않는다. **enum에 없는 값이면 `ArgumentError`로 떨어진다.**

```ruby
@category = Notice.categories.key?(params[:category]) ? params[:category] : nil
```

## 월별 집계 — 컬럼에 함수를 씌우지 않는다

`in_month` 처럼 연월로 거를 때 `EXTRACT(YEAR FROM spent_on) = ?` 를 쓰면
**컬럼에 함수가 씌워져 인덱스가 먹지 않는다.** 범위 조건으로 쓴다.

```ruby
first_day = Date.new(year, month, 1)
where(spent_on: first_day..first_day.end_of_month)
```

`available_year_months` 처럼 "기록이 있는 연월"을 뽑을 때는 전건을 Ruby 로
읽지 않고 `date_trunc`(PostgreSQL 고유)로 월 단위로 뭉쳐 `distinct` 한다.
이때 `reorder(nil)` 이 필요하다 — 정렬이 붙은 릴레이션에서 부르면
`SELECT DISTINCT` 와 `ORDER BY` 가 충돌해 PostgreSQL 이 에러를 낸다.

`sales_record.rb` 와 `expense_record.rb` 가 같은 형태를 쓴다.

## N+1

목록을 만들 때는 **쿼리 수를 세는 스펙**을 같이 쓴다. 다만 쿼리 수가 줄었다고 끝이 아니다 — **성능 검증과 표시 검증은 다른 축**이다. 쿼리를 줄이려고 바꾼 코드가 화면 결과를 망가뜨릴 수 있다.

Active Storage·Action Text에서 특히 걸린다.

| 쓰면 N+1 | 대신 |
| --- | --- |
| `content.body.attachables` | `content.embeds` (선읽기됨) |
| `content.to_plain_text` | HTML에서 태그 제거 |
