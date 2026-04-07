# health_recordsテーブルの重複インデックスを削除するマイグレーション
# t.referencesが自動生成したインデックス（Railsの慣例名）を残し、
# add_indexで手動追加した重複インデックス（カスタム名）を削除する
class RemoveDuplicateHealthRecordsIndexes < ActiveRecord::Migration[8.0]
  def change
    # add_indexで手動追加した重複インデックスを削除（自動生成のindex_health_records_on_animal_idを残す）
    remove_index :health_records, name: "idx_health_records_animal_id"
    # add_indexで手動追加した重複インデックスを削除（自動生成のindex_health_records_on_created_by_idを残す）
    remove_index :health_records, name: "idx_health_records_created_by"
  end
end
