# ERD — 테이블 14개와 선 16개

그림은 `docs/erd.png` 다. **ErdCloud 에서 손으로 그린다** — 생성 도구가 없으므로 스키마를 바꾸면 그림이 자동으로 따라오지 않는다.

이 문서가 있는 이유가 그것이다. **어긋남은 `git diff` 에 걸려야 한다.** 그림은 PNG 라 diff 가 「바뀌었다」까지만 말하고 무엇이 바뀌었는지는 말하지 않는다.

---

## 테이블 14개

| 테이블 | 역할 | 비고 |
| --- | --- | --- |
| `zones` | 전시관 | 읽기 전용. 6행 고정 |
| `animal_categories` | 관 안의 분류 | `(zone_id, name)` 유일 |
| `animals` | 동물 개체 **대장** | `created_by_id` 가 **없다** — 기록이 아니라 대장이다 |
| `health_records` | 건강 기록 | |
| `feeding_records` | 먹이 기록 | |
| `notices` | 공지 | 본문은 여기 없다 |
| `sales_records` | 매출 | `(sold_on, source)` 유일 |
| `expense_records` | 지출 | |
| `users` | 계정 | 퇴사는 `active = false` 논리 삭제 |
| `action_text_rich_texts` | 공지 본문 HTML | Action Text |
| `active_storage_blobs` | 파일 실체 | `updated_at` 이 **없다** |
| `active_storage_attachments` | 첨부 연결 | 세 종류를 한 테이블로 받는다 |
| `active_storage_variant_records` | 썸네일 등 변환본 | |
| `solid_cache_entries` | 캐시 저장소 | **ERD 에 안 그린다**(아래) |

도메인 9개는 전부 UUID v4(`gen_random_uuid()`)다. `solid_cache_entries` 만 bigserial 이고, 그것도 ERD 에서 빼는 이유 중 하나다.

---

## 선 16개 — 12개만 외래키다

### 외래키 12개

DB 가 보장한다. 깨진 참조는 **INSERT 가 실패**한다.

| 자식 | 컬럼 | 부모 | 비고 |
| --- | --- | --- | --- |
| `animals` | `zone_id` | `zones` | NOT NULL |
| `animals` | `animal_category_id` | `animal_categories` | **nullable**, `ON DELETE SET NULL` |
| `animal_categories` | `zone_id` | `zones` | NOT NULL |
| `health_records` | `animal_id` | `animals` | NOT NULL |
| `feeding_records` | `animal_id` | `animals` | NOT NULL |
| `health_records` | `created_by_id` | `users` | nullable |
| `feeding_records` | `created_by_id` | `users` | nullable |
| `notices` | `created_by_id` | `users` | nullable |
| `sales_records` | `created_by_id` | `users` | nullable |
| `expense_records` | `created_by_id` | `users` | nullable |
| `active_storage_attachments` | `blob_id` | `active_storage_blobs` | NOT NULL |
| `active_storage_variant_records` | `blob_id` | `active_storage_blobs` | NOT NULL |

`created_by_id` 가 전부 nullable 인 것은 **계정을 지워도 기록은 남아야** 하기 때문이다. 다만 퇴사는 논리 삭제라 실제로 NULL 이 되는 경로는 없다 — 감사 추적을 보존하려는 쪽과 같은 판단이다.

### 폴리모픽 4개 — 외래키가 아니다

| 자식 | 무엇으로 | 부모 | `record_type` |
| --- | --- | --- | --- |
| `action_text_rich_texts` | `record_type` + `record_id` | `notices` | `Notice` |
| `active_storage_attachments` | `record_type` + `record_id` | `animals` | `Animal` |
| `active_storage_attachments` | `record_type` + `record_id` | `action_text_rich_texts` | `ActionText::RichText` |
| `active_storage_attachments` | `record_type` + `record_id` | `active_storage_variant_records` | `ActiveStorage::VariantRecord` |

`name` 이 네 번째 칸을 가른다 — `content` · `photo` · `embeds` · `image` 순이다.

**`REFERENCES` 를 못 거는 이유**는 가리키는 테이블이 행마다 다르기 때문이다. `active_storage_attachments` 한 테이블이 동물 사진도, 공지 본문의 이미지도, 썸네일도 받는다. `REFERENCES` 뒤에 테이블 이름을 하나로 적을 수 없어서 **테이블 이름 자체를 문자열 칸에 담는다.**

그래서 **DB 가 아무것도 막지 않는다.** 존재하지 않는 UUID 를 `record_id` 에 넣고 INSERT 하면 그대로 들어간다(실측). 잇는 쪽은 Rails 다.

> 같은 뿌리의 함정이 `notes/animal-photo.md` 에 있다. 동물 행을 지울 때 사진을 지우는 것은 DB 의 `ON DELETE` 가 아니라 Rails 의 `dependent` 다. **Rails 가 안 돌면 아무도 안 치운다** — 잡 워커 없는 `purge_later` 가 고아 파일을 남기는 이유가 그것이다.

---

## 그림에 담기지 않은 것

### 폴리모픽 4개는 선을 긋지 않았다

ErdCloud 의 관계선이 **전부 같은 모양**이라, 실선/점선으로 「DB 가 보장하는 것」과 「앱이 보장하는 것」을 가를 수 없다.

그 상태에서 선을 4개 더 그으면 **기존 12개와 구별되지 않아** 보는 사람이 전부 외래키라고 읽는다. 없는 제약을 있다고 말하는 쪽이, 선이 없는 쪽보다 나쁘다.

그래서 `action_text_rich_texts` 가 그림에서 **아무 데도 안 붙은 채 떠 있다.** 빠뜨린 것이 아니다. 어디에 붙는지는 위 표가 말한다.

### `solid_cache_entries` 는 안 그린다

Rails 의 캐시 저장소라 도메인 테이블이 아니고 **관계선이 하나도 없다.** 그리면 떠 있는 섬이 하나 더 생겨서, 위의 「떠 있는 것은 폴리모픽이다」라는 읽기가 망가진다.

### CHECK 제약 14개

그림에 안 들어간다. `db/schema.rb` 를 본다. 가장 중요한 둘은 `animals` 에 있다.

```sql
CHECK ((active = false) = (exit_reason IS NOT NULL))
CHECK ((exit_reason IS NULL) = (exited_on IS NULL))
```

판단은 `notes/animal-lifecycle.md` 에 있다.

---

## 스키마를 바꾸면

```
1. 마이그레이션 → db/schema.rb 가 자동 갱신된다
2. 이 문서의 표를 고친다          ← git diff 에 걸리는 자리
3. ErdCloud 에서 그림을 고친다
4. docs/erd.png 을 교체한다
```

2 와 3 을 사람이 해야 한다. **3 을 빠뜨리면 2 로 알아챌 수 있지만, 2 를 빠뜨리면 알아챌 방법이 없다.** 그래서 2 를 먼저 한다.

> Mermaid 로 바꿔 CI 가 `schema.rb` 와 대조하게 하는 안을 검토했다. 지금은 테이블이 14개뿐이고 스키마가 달에 한 번도 안 바뀌어서, 들이는 품에 비해 얻는 것이 적다고 보고 미뤘다.
