# animals 테이블
class CreateAnimals < ActiveRecord::Migration[8.1]
  def change
    # 잘못 만든 animals 테이블을 지우고 올바른 구조로 다시 만든다
    drop_table :animals, if_exists: true

    create_table :animals, id: :uuid do |t|
      t.references :zone,             null: false, foreign_key: true, type: :uuid  # 소속 관
      t.string     :name,             limit: 100                              # 개체명
      t.string     :species,          null: false, limit: 100                 # 종 이름 (예: 코자쿠라인코)
      t.integer    :gender,           null: false, default: 2, limit: 2       # 성별
      t.date       :birth_date                                                # 생년월일 (모르면 NULL)
      t.date       :acquired_at                                               # 입수일
      t.text       :acquisition_note                                          # 입수 경위 (구매/기증/자연번식 등)
      t.integer    :cites_grade,      null: false, default: 0, limit: 2       # CITES 등급 enum: 0=none 1=I 2=II 3=III
      t.boolean    :active,           null: false, default: true              # false=사망·방출 (논리 삭제)
      t.text       :note                                                      # 바뀌지 않는 특이사항
      t.timestamps
    end

    add_index :animals, :zone_id, name: "idx_animals_zone_id"
  end
end
