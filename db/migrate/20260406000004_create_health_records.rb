# health_records 테이블
class CreateHealthRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :health_records, id: :uuid do |t|
      # 동물이 지워져도 기록은 남기는 설계
      t.references :animal,     null: false, foreign_key: true, type: :uuid
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      # 실제 관찰일 (created_at 과 분리 — 어제 관찰한 것을 오늘 입력하는 일이 생긴다)
      t.date       :recorded_on, null: false
      t.decimal    :weight_kg,   precision: 6, scale: 2
      # 0=normal, 1=caution, 2=danger
      t.integer    :condition,   null: false, default: 0
      t.text       :note

      t.timestamps
    end

    # condition 을 0/1/2 로만 제한하는 CHECK 제약
    add_check_constraint :health_records,
                         "condition IN (0, 1, 2)",
                         name: "chk_health_condition"

    add_index :health_records, :animal_id,   name: "idx_health_records_animal_id"
    # 권한 확인에서 자주 쓴다
    add_index :health_records, :created_by_id, name: "idx_health_records_created_by"
    # 동물 × 관찰일 복합 — 시계열 표시에서 자주 쓴다
    add_index :health_records, %i[animal_id recorded_on],
              name: "idx_health_records_animal_date"
  end
end
