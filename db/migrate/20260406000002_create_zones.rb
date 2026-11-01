# zones 테이블 — 시드로 고정 관리한다
class CreateZones < ActiveRecord::Migration[8.1]
  def change
    create_table :zones, id: :uuid do |t|
      t.string :name,        null: false, limit: 100  # 관 이름 (예: 사랑새관)
      t.text   :description                            # 관 설명 (선택)

      t.timestamps
    end

    add_index :zones, :name, unique: true
  end
end
