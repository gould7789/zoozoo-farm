# health_records 의 인덱스 이름을 Rails 관례명으로 통일한다
class FixHealthRecordsIndexes < ActiveRecord::Migration[8.0]
  def up
    # 커스텀 이름 인덱스를 지운다 (있을 때만)
    remove_index :health_records, name: "idx_health_records_animal_id", if_exists: true
    remove_index :health_records, name: "idx_health_records_created_by", if_exists: true
    # 관례명으로 다시 더한다 (t.references 가 만드는 것과 같은 규칙)
    add_index :health_records, :animal_id,    if_not_exists: true
    add_index :health_records, :created_by_id, if_not_exists: true
  end

  def down
    remove_index :health_records, :animal_id
    remove_index :health_records, :created_by_id
    add_index :health_records, :animal_id,    name: "idx_health_records_animal_id"
    add_index :health_records, :created_by_id, name: "idx_health_records_created_by"
  end
end
