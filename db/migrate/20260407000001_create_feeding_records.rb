# 給餌記録テーブルを作成するマイグレーション
class CreateFeedingRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :feeding_records do |t|
      # 対象動物
      t.references :animal,     null: false, foreign_key: true
      # 作成者
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      # 給餌日時（日付＋時刻）
      t.datetime   :fed_at,     null: false
      # 餌の種類（ペレット、野菜、果物など）
      t.string     :food_type,  null: false, limit: 100
      # 給餌量g（任意、整数で管理しkg換算より直感的）
      t.integer    :amount_g
      # 給餌時の特記事項（任意）
      t.text       :note

      t.timestamps
    end

    # 給餌日時での検索に使用するインデックス
    add_index :feeding_records, :fed_at
  end
end
