# sales_recordsのsold_onに重複インデックスが存在するため手動追加分を削除する
# 複合ユニークインデックス(sold_on, source)がsold_onを先頭カラムに持つため、
# sold_on単独の条件（in_monthのBETWEEN範囲検索を含む）もそちらでカバーされる
# 単独インデックスは書き込みのたびに更新コストを払うだけで使われていない
#
# expense_recordsのspent_onは先頭に持つ複合インデックスが無いため重複ではない — 残す
class RemoveDuplicateSoldOnIndexFromSalesRecords < ActiveRecord::Migration[8.1]
  def change
    # カラムも渡すとrollback可能になる（name:だけだとIrreversibleMigrationになる）
    remove_index :sales_records, :sold_on, name: "index_sales_records_on_sold_on"
  end
end
