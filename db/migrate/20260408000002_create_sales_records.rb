# sales_records 테이블 (Admin 전용)
class CreateSalesRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :sales_records, id: :uuid do |t|
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.date    :sold_on, null: false
      # 판매처 enum (0=자판기1, 1=자판기2, 2=자판기3, 3=자판기4, 4=매점)
      t.integer :source,  null: false
      # 매출액 — 원 단위 정수
      t.integer :amount,  null: false
      t.text    :note

      t.timestamps
    end

    # 같은 날 같은 판매처의 중복을 막는 복합 UNIQUE
    add_index :sales_records, [ :sold_on, :source ], unique: true
    add_index :sales_records, :sold_on
  end
end
