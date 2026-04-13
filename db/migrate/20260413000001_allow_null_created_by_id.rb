# created_by_idのNOT NULL制約を解除 — ユーザー削除時にdependent: :nullifyが機能するよう変更
class AllowNullCreatedById < ActiveRecord::Migration[8.0]
  def change
    change_column_null :health_records,   :created_by_id, true
    change_column_null :feeding_records,  :created_by_id, true
    change_column_null :notices,          :created_by_id, true
    change_column_null :sales_records,    :created_by_id, true
    change_column_null :expense_records,  :created_by_id, true
  end
end
