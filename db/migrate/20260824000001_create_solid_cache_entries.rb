# solid_cacheのバッキングテーブル — 本番のcache_storeが:solid_cache_store
#
# 元々はdb/cache_schema.rb（cache専用DB向け）にあったが、一度も作られていなかった。
# database.ymlのcache:はmigrations_pathsにdb/cache_migrateを指しており、
# そのディレクトリが存在しないためdb:migrateが何も実行しなかったのが原因。
#
# Render free + Supabaseはデータベースが1つしか無く、DATABASE_URLの
# データベース名がdatabase.ymlのdatabase:キーを上書きするため、cache接続は
# 結局primaryと同じDBに解決される。分ける意味が無いので通常のマイグレーションで作る。
#
# 主キーはUUIDにしない（プロジェクト既定はUUIDv4）。
# solid_cacheの期限切れ削除がEntry.id_rangeとorder(:id)に依存しており、
# 単調増加する整数でないと退避対象の選定が壊れる。
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
