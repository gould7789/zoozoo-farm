---
paths:
  - "db/migrate/**/*.rb"
---

# 마이그레이션

## 이 코드는 운영 DB에 실행된다

배포하면 Render가 `db:migrate`를 돌린다. 되돌릴 수 없는 변경을 하기 전에 멈춰 생각한다.

- `down`을 **반드시** 구현한다. `irreversible`로 두지 않는다
- 데이터를 변환하는 마이그레이션은 **스펙을 쓴다** (`spec/migrations/`)
- PR 본문에 **배포 후 확인 쿼리**를 적는다

## PostgreSQL 문법을 우선한다

UUID 기본키를 쓴다. `gen_random_uuid()` (pgcrypto).

```ruby
create_table :notices, id: :uuid, default: -> { "gen_random_uuid()" }
```

`config/application.rb`의 `primary_key_type: :uuid` 덕에 **생성기가 만든 마이그레이션도 uuid로 나온다.** 손댈 필요 없다.

## 값을 보간하는 SQL에 `squish`를 쓰지 않는다

```ruby
# 이렇게 쓰면 보간된 본문의 줄바꿈까지 뭉갠다
execute <<~SQL.squish
  UPDATE notices SET body = #{quote(plain)} WHERE id = #{quote(id)}
SQL

# 값을 보간할 때는 squish 없이
execute <<~SQL
  UPDATE notices SET body = #{quote(plain)} WHERE id = #{quote(id)}
SQL
```

`squish`는 SQL의 들여쓰기만 정리하는 게 아니라 **값 안의 개행까지** 공백으로 바꾼다. 값을 보간하지 않는 순수 SQL에만 쓴다.

**보간하는 모든 값은 `quote()`를 거친다.** 예외 없다.

## 컬럼을 남기는 것과 제약을 남기는 것은 다르다

보관용으로 컬럼을 남길 때 **`NOT NULL`을 같이 생각해야 한다.** 컬럼만 남기고 제약을 그대로 두면 새 레코드 생성이 DB 레벨에서 떨어진다.

```ruby
change_column_null :notices, :body, true
```

## `down`은 실제로 돌아가야 한다

`up`을 되돌리는 것만으로 부족한 경우가 있다. 예를 들어 이관 후 **새로 만들어진 레코드**는 옛 컬럼이 비어 있어서, 그대로 `NOT NULL`을 복원하면 `down` 자체가 실패한다.

```ruby
def down
  # ① 이관 후 생긴 행을 먼저 채운다
  # ② 그다음 제약을 되돌린다
end
```

## 2단계 이관

컬럼을 바꿀 때는 **한 번에 지우지 않는다.**

```
PR 1   새 저장소로 전환. 옛 컬럼은 읽지도 쓰지도 않는 보관용으로 남긴다
         → 배포하고 운영에서 확인한다
PR 2   확인이 끝나면 옛 컬럼을 드롭한다
```

PR 1 상태에서는 `git revert` 한 번으로 **원본이 살아 있는 상태**로 돌아온다.

> 이때 **새 접근자의 이름이 옛 컬럼과 겹치지 않아야** 한다. 겹치면 이관 스크립트가 `read_attribute`로 우회해야 하고, 같은 이름이 두 대상을 가리키는 채로 배포하게 된다.

## 데이터 변환 시 원문 보존

평문을 HTML로 바꿀 때 `simple_format`의 기본 살균은 **태그를 벗기고 안의 텍스트만 남긴다.** 원문이 조용히 변형된다.

```ruby
helpers.simple_format(ERB::Util.html_escape(text), {}, sanitize: false)
```

## 마이그레이션 스펙은 배포와 같은 순서로 재현한다

```ruby
# 제목이 있는 상태로 레코드를 만들고 → 컬럼을 떨어뜨리고 → 이관
def run_migration
  ActiveRecord::Base.connection.remove_column(:notices, :title)
  Notice.reset_column_information
  migration.up
  Notice.reset_column_information
end
```

PostgreSQL은 DDL도 트랜잭션에 실리므로 example이 끝나면 컬럼이 돌아온다.
