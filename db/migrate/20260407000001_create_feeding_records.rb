# feeding_records 테이블
class CreateFeedingRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :feeding_records, id: :uuid do |t|
      t.references :animal,     null: false, foreign_key: true, type: :uuid
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      # 급여 일시 (날짜 + 시각)
      t.datetime   :fed_at,     null: false
      # 먹이 종류 (펠렛, 채소, 과일 등)
      t.string     :food_type,  null: false, limit: 100
      t.integer    :amount_g
      t.text       :note

      t.timestamps
    end

    add_index :feeding_records, :fed_at
  end
end
