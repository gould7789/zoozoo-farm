# 動物個体テーブルを作成するマイグレーション
class CreateAnimals < ActiveRecord::Migration[8.1]
  def change
    # 既存の誤ったanimalsテーブルを削除してから正しい構造で再作成する
    drop_table :animals, if_exists: true

    create_table :animals do |t|
      t.references :zone,             null: false, foreign_key: true
      t.string     :name,             limit: 100
      t.string     :species,          null: false, limit: 100
      t.integer    :gender,           null: false, default: 2, limit: 2
      t.date       :birth_date
      t.date       :acquired_at
      t.text       :acquisition_note
      t.integer    :cites_grade,      null: false, default: 0, limit: 2
      t.boolean    :active,           null: false, default: true
      t.text       :note

      t.timestamps
    end

    add_index :animals, :zone_id, name: "idx_animals_zone_id"
  end
end
