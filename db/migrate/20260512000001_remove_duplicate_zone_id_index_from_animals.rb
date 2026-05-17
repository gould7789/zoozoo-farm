# animalsテーブルのzone_idに重複インデックスが存在するため、手動追加分を削除する
# t.referencesが自動生成したindex_animals_on_zone_idを残す
class RemoveDuplicateZoneIdIndexFromAnimals < ActiveRecord::Migration[8.1]
  def change
    remove_index :animals, name: "idx_animals_zone_id"
  end
end
