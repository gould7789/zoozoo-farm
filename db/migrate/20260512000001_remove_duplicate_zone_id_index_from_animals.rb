# animals.zone_id 에 중복 인덱스가 있어 손수 더한 쪽을 지운다.
# t.references 가 만든 index_animals_on_zone_id 를 남긴다
class RemoveDuplicateZoneIdIndexFromAnimals < ActiveRecord::Migration[8.1]
  def change
    remove_index :animals, name: "idx_animals_zone_id"
  end
end
