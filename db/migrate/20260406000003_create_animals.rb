# 動物個体テーブルを作成するマイグレーション
class CreateAnimals < ActiveRecord::Migration[8.1]
  def change
    # 既存の誤ったanimalsテーブルを削除してから正しい構造で再作成する
    drop_table :animals, if_exists: true

    create_table :animals, id: :uuid do |t|
      t.references :zone,             null: false, foreign_key: true, type: :uuid  # 所属館
      t.string     :name,             limit: 100                              # 個体名
      t.string     :species,          null: false, limit: 100                 # 種名（例: インコ）
      t.integer    :gender,           null: false, default: 2, limit: 2       # 性別
      t.date       :birth_date                                                # 生年月日（NULL許容: 不明の場合）
      t.date       :acquired_at                                               # 入手日
      t.text       :acquisition_note                                          # 入手経緯（購入/寄贈/自然繁殖など）
      t.integer    :cites_grade,      null: false, default: 0, limit: 2       # CITES区分 enum: 0=none 1=I 2=II 3=III
      t.boolean    :active,           null: false, default: true              # false=死亡/放出（論理削除）
      t.text       :note                                                      # 固定特記事項
      t.timestamps
    end

    # zone_idで動物を絞り込む検索が多いためインデックスを追加
    add_index :animals, :zone_id, name: "idx_animals_zone_id"
  end
end
