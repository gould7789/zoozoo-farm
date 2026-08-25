# 金額に負数が入らないようDB側にもCHECK制約を張る
#
# モデルには既にnumericality: { greater_than_or_equal_to: 0 }があるが、
# update_all・insert_all・生SQL・バックフィルはモデル検証を通らない。
# 売上と支出は監査対応のテーブルで、負数が混ざると合計が静かに狂う。
# 例外も警告も出ないので、気づく手段がバリデーション頼みでは足りない。
#
# 上限（<= 9_999_999）はDBに降ろさない。物理的な整合性ではなく
# 「1日の売上が1000万を超えるなら入力ミスだろう」という業務規則で、変わり得る。
#
# 本番データに違反行が無いことをSupabase上で確認済み（両テーブルとも0件）。
# 違反行があるとADD CONSTRAINTが失敗し、デプロイのビルドごと止まる。
class AddAmountCheckConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :sales_records,   "amount >= 0", name: "chk_sales_amount"
    add_check_constraint :expense_records, "amount >= 0", name: "chk_expense_amount"
  end
end
