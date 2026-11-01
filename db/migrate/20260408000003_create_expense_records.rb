# expense_records 테이블 (Admin 전용)
class CreateExpenseRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :expense_records, id: :uuid do |t|
      t.references :created_by,   null: false, foreign_key: { to_table: :users }, type: :uuid
      t.date        :spent_on,    null: false
      # 0=동물 구매비, 1=먹이 구매비, 2=병원비, 3=시체 처리비, 4=시설 유지보수, 5=기타
      t.integer     :category,    null: false
      # 지출액 — 원 단위 정수
      t.integer     :amount,      null: false
      t.text        :description, null: false

      t.timestamps
    end

    add_index :expense_records, :spent_on
    add_index :expense_records, :category
    # created_by_id 인덱스는 t.references 가 만들므로 더하지 않는다
  end
end
