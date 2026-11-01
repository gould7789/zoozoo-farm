# sales_records.sold_on 에 중복 인덱스가 있어 손수 더한 쪽을 지운다.
# 복합 UNIQUE (sold_on, source) 가 sold_on 을 선두 컬럼으로 가지므로
# sold_on 단독 조건(in_month 의 BETWEEN 범위 검색 포함)도 그쪽으로 덮인다.
# 단독 인덱스는 쓸 때마다 갱신 비용만 내고 쓰이지 않는다
#
# expense_records.spent_on 은 선두로 가지는 복합 인덱스가 없어 중복이 아니다 — 남긴다
class RemoveDuplicateSoldOnIndexFromSalesRecords < ActiveRecord::Migration[8.1]
  def change
    # 컬럼도 넘기면 rollback 이 된다 (name: 만 주면 IrreversibleMigration)
    remove_index :sales_records, :sold_on, name: "index_sales_records_on_sold_on"
  end
end
