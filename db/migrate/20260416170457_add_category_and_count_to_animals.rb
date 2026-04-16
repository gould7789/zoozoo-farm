# animalsテーブルにカテゴリ外部キーと個体数カラムを追加するマイグレーション
# animal_category_idはNULL許容 — カテゴリ未分類の動物が存在するため
# individual_countは多頭種（ウサギ・モルモット等）の頭数管理用
class AddCategoryAndCountToAnimals < ActiveRecord::Migration[8.1]
  def change
    # カテゴリ削除時はNULLに設定（動物自体は削除しない）
    add_reference :animals, :animal_category,
                  type:        :uuid,
                  null:        true,
                  foreign_key: { on_delete: :nullify }

    # 個体数 — デフォルト1、1以上の制約をDBレベルでも担保
    add_column :animals, :individual_count, :integer, null: false, default: 1

    add_check_constraint :animals, "individual_count >= 1",
                         name: "chk_animals_individual_count"
  end
end
