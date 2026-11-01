# created_by_id 의 NOT NULL 을 뗀다 — 사용자 삭제 시 dependent: :nullify 가 듣게
class AllowNullCreatedById < ActiveRecord::Migration[8.0]
  def change
    change_column_null :health_records,   :created_by_id, true
    change_column_null :feeding_records,  :created_by_id, true
    change_column_null :notices,          :created_by_id, true
    change_column_null :sales_records,    :created_by_id, true
    change_column_null :expense_records,  :created_by_id, true
  end
end
