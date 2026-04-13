# health_recordsのインデックスをRailsの慣例名に統一するマイグレーション
# カスタム名インデックスを削除し、Railsが自動生成する慣例名インデックスを追加する
class FixHealthRecordsIndexes < ActiveRecord::Migration[8.0]
  def up
    # カスタム名インデックスを削除（存在する場合のみ）
    remove_index :health_records, name: "idx_health_records_animal_id", if_exists: true
    remove_index :health_records, name: "idx_health_records_created_by", if_exists: true
    # Railsの慣例名でインデックスを追加（t.referencesの自動生成と同じ命名規則）
    add_index :health_records, :animal_id,    if_not_exists: true
    add_index :health_records, :created_by_id, if_not_exists: true
  end

  def down
    remove_index :health_records, :animal_id
    remove_index :health_records, :created_by_id
    add_index :health_records, :animal_id,    name: "idx_health_records_animal_id"
    add_index :health_records, :created_by_id, name: "idx_health_records_created_by"
  end
end
