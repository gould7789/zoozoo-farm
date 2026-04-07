# 健康記録テーブルの作成マイグレーション
# 動物ごとの日々の健康観察データを管理する
class CreateHealthRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :health_records do |t|
      # 対象動物（動物が削除されても記録は残す設計）
      t.references :animal,     null: false, foreign_key: true
      # 作成者
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      # 実際の観察日（created_atと分離 — 昨日観察した内容を今日入力するケースがある）
      t.date       :recorded_on, null: false
      # 体重
      t.decimal    :weight_kg,   precision: 6, scale: 2
      # コンディション: 0=normal, 1=caution, 2=danger
      t.integer    :condition,   null: false, default: 0
      # 自由記述の特記事項
      t.text       :note

      t.timestamps
    end

    # condition の値を 0/1/2 のみに制限する CHECK 制約
    add_check_constraint :health_records,
                         "condition IN (0, 1, 2)",
                         name: "chk_health_condition"

    # 動物IDでの検索用インデックス
    add_index :health_records, :animal_id,   name: "idx_health_records_animal_id"
    # 作成者IDでの検索用インデックス（権限チェック頻度が高い）
    add_index :health_records, :created_by_id, name: "idx_health_records_created_by"
    # 動物 × 観察日の複合インデックス（時系列表示で頻繁に使用）
    add_index :health_records, %i[animal_id recorded_on],
              name: "idx_health_records_animal_date"
  end
end
