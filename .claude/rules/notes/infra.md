---
paths:
  - "config/database.yml"
  - "config/cache.yml"
  - "config/cable.yml"
  - "config/storage.yml"
  - "config/application.rb"
  - "config/environments/production.rb"
  - "config/environments/test.rb"
  - "db/migrate/*_create_solid_cache_entries.rb"
---

# 배포 환경이 설정에 남긴 것

| 항목 | 내용 |
| --- | --- |
| 플랫폼 | Render 무료 플랜 (메모리 512MB, 잠든다) |
| DB | Supabase 관리형 PostgreSQL — **데이터베이스가 하나뿐** |
| 스토리지 | Supabase Storage (S3 프로토콜) |
| 앱 서버 | Puma |

**이 두 줄이 설정 여러 곳의 근거다.** 모르면 「왜 나누지 않았나」로 읽힌다.

## DB 가 하나뿐이라는 것

Solid Cache / Queue / Cable 을 **연결을 나누지 않고 primary 에 올린다.**

`DATABASE_URL` 이 있으면 **URL 쪽의 DB 이름이 `database.yml` 의 `database:` 키를 덮어쓴다.** 그래서 `cache:` 에 다른 이름을 써도 결국 같은 DB 로 풀린다. 나눠 쓴 것처럼 보이는 설정이 실제로는 나뉘지 않는다.

이게 **실제로 버그를 만들었다.** `database.yml` 의 `cache:` 가 `migrations_paths` 로 `db/cache_migrate` 를 가리키는데 그 디렉토리가 없어, `db:migrate` 가 캐시 테이블을 **한 번도 만들지 않았다.** 운영 `cache_store` 가 `:solid_cache_store` 라 테이블이 없으면 `increment` 가 `UndefinedTable` 로 떨어진다 — 그러면 **rate limit 이 조용히 전부 통과한다.**

> 그래서 `spec/requests/sessions_spec.rb` 에 「테이블이 스키마에 있는가」와 「`increment` 가 더한 값을 돌려주는가」를 따로 둔다. 그 둘이 없으면 스토어가 깨진 것을 못 잡는다.

### solid_cache 의 기본키만 UUID 가 아니다

프로젝트 기본은 UUID v4 인데 `solid_cache_entries` 는 정수다. **기한 만료 삭제가 `Entry.id_range` 와 `order(:id)` 에 의존**해서, 단조 증가하는 정수가 아니면 지울 대상을 고르는 것이 깨진다.

## 영속 디스크가 없다는 것

재배포·재기동마다 Disk 서비스의 파일이 사라진다. 그래서 첨부를 **외부 스토리지에 둔다.**

`force_path_style` 은 필수다. AWS S3 는 버킷을 서브도메인에 두지만(`bucket.s3.amazonaws.com`) **Supabase 는 경로 방식만 받는다.** 빠지면 원인을 알기 어려운 403 이 된다.

ENV 에서 읽는 건 **비밀 정보와 프로젝트 식별자뿐**이다. `region` · `bucket` 은 노출돼도 의미가 없으므로 리터럴로 두어 설정 누락의 여지를 줄인다.

## 잡 워커가 없다는 것

Active Job 은 Rails 기본 `:async` 그대로다. `solid_queue` 를 넣지 않았고 잡을 쓰는 자리도 없다.

여기서 나오는 판단들 — variant 를 `preprocessed` 로 미리 만들지 않는 것, 사진 삭제를 `purge_later` 가 아니라 `purge` 로 하는 것(`notes/animal-photo.md`), 이미지를 브라우저에서 줄여 보내는 것(`notes/notice.md`).

Action Cable 도 쓰는 곳이 0건이라(채널·broadcast·`turbo_stream_from` 전부 없음) `async` 로 둔다.

## 타임존

로컬 macOS 는 KST, **서버는 UTC** 다. 그래서 `config.time_zone` 을 KST 로 고정한다 — 안 잡으면 `created_at` 표시와 `Date.current` 가 9시간 어긋난다.

**과거에 실제로 데이터가 틀어졌다.** `db/migrate/*_correct_feeding_records_fed_at_timezone.rb` 가 그 보정이다. 시간·날짜를 다루는 작업은 `TZ=UTC` 로도 테스트를 돌린다.

## 첨부는 proxy 로 배포한다

`config.active_storage.resolve_model_to_route = :rails_storage_proxy`.

기본값인 redirect 는 스토리지 도메인으로 302 하고 **CSP 는 리다이렉트 뒤의 호스트를 보므로** `img_src 'self'` 에 막힌다. 뷰마다 헬퍼를 고르는 방식이면 **한 곳만 빠뜨려도 그 화면이 깨지므로**, 기본값을 안전한 쪽으로 눕혀 예외를 만들지 않는다.

## 테스트 환경만 memory_store 다

`null_store` 는 `increment` 가 `nil` 을 돌려줘 `rate_limit` 의 판정(`count && count > to`)이 **항상 통과한다.** 그러면 제한 자체의 스펙을 쓸 수 없다.
