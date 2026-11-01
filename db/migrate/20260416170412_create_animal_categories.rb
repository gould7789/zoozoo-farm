# animal_categories 테이블
# 카테고리는 관에 붙어 동물을 묶는다 (예: 알파카, 토끼)
# 카테고리를 지우면 소속 동물의 animal_category_id 는 NULL 이 된다 (물리 삭제는 하지 않는다)
class CreateAnimalCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :animal_categories, id: :uuid do |t|
      # 관을 지우면 카테고리도 지운다
      t.references :zone, null: false, foreign_key: true, type: :uuid
      # 카테고리 이름 (예: 알파카, 코자쿠라인코)
      t.string :name, null: false, limit: 100
      t.timestamps
    end

    add_index :animal_categories, [ :zone_id, :name ], unique: true,
              name: "idx_animal_categories_zone_name"
  end
end
