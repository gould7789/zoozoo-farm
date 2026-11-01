# health_records 의 중복 인덱스를 지운다.
# t.references 가 자동 생성한 것(Rails 관례명)을 남기고
# add_index 로 손수 더한 중복(커스텀 이름)을 지운다
class RemoveDuplicateHealthRecordsIndexes < ActiveRecord::Migration[8.0]
  def change
    remove_index :health_records, name: "idx_health_records_animal_id"
    remove_index :health_records, name: "idx_health_records_created_by"
  end
end
