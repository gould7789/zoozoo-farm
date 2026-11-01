# solid_cache 의 백킹 테이블 — 운영의 cache_store 가 :solid_cache_store 다
#
# 원래는 db/cache_schema.rb(캐시 전용 DB 용)에 있었지만 한 번도 만들어지지 않았다.
# database.yml 의 cache: 가 migrations_paths 로 db/cache_migrate 를 가리키는데
# 그 디렉토리가 없어 db:migrate 가 아무것도 실행하지 않은 것이 원인이다.
#
# Render free + Supabase 는 데이터베이스가 하나뿐이고, DATABASE_URL 의 DB 이름이
# database.yml 의 database: 를 덮어쓰므로 cache 연결도 결국 primary 와 같은 DB 로
# 풀린다. 나눌 의미가 없어 보통 마이그레이션으로 만든다.
#
# 기본키를 UUID 로 하지 않는다 (프로젝트 기본은 UUIDv4).
# solid_cache 의 기한 만료 삭제가 Entry.id_range 와 order(:id) 에 의존해,
# 단조 증가하는 정수가 아니면 지울 대상을 고르는 것이 깨진다.
class CreateSolidCacheEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cache_entries do |t|
      t.binary   :key,        limit: 1024,        null: false
      t.binary   :value,      limit: 536_870_912, null: false
      t.datetime :created_at,                     null: false
      t.integer  :key_hash,   limit: 8,           null: false
      t.integer  :byte_size,  limit: 4,           null: false

      t.index :key_hash, unique: true
      t.index [ :key_hash, :byte_size ]
      t.index :byte_size
    end
  end
end
