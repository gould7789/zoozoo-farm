# animals 에 카테고리 외래 키와 개체 수 컬럼을 더한다
# animal_category_id 는 NULL 허용 — 미분류 동물이 있다
# individual_count 는 토끼·기니피그처럼 여러 마리를 한 기록으로 다루는 종에 쓴다
class AddCategoryAndCountToAnimals < ActiveRecord::Migration[8.1]
  def change
    # 카테고리를 지우면 NULL 로 (동물 자체는 지우지 않는다)
    add_reference :animals, :animal_category,
                  type:        :uuid,
                  null:        true,
                  foreign_key: { on_delete: :nullify }

    # 개체 수 — 기본 1, 1 이상 제약을 DB 에서도 담보한다
    add_column :animals, :individual_count, :integer, null: false, default: 1

    add_check_constraint :animals, "individual_count >= 1",
                         name: "chk_animals_individual_count"
  end
end
