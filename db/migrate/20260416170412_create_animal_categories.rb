# 動物カテゴリテーブルを作成するマイグレーション
# カテゴリは館に紐づき、動物をグループ分けする（例: アルパカ、ウサギ）
# カテゴリ削除時は所属動物のanimal_category_idをNULLに設定（物理削除はしない）
class CreateAnimalCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :animal_categories, id: :uuid do |t|
      # 所属館 — 館削除時はカテゴリも削除
      t.references :zone, null: false, foreign_key: true, type: :uuid
      # カテゴリ名（例: アルパカ、コザクラインコ）
      t.string :name, null: false, limit: 100
      t.timestamps
    end

    # 同じ館内でカテゴリ名が重複しないようにUNIQUEインデックスを追加
    add_index :animal_categories, [ :zone_id, :name ], unique: true,
              name: "idx_animal_categories_zone_name"
  end
end
