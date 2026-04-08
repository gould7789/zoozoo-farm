# 売上記録テーブルの作成マイグレーション（Admin専用）
class CreateSalesRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :sales_records do |t|
      # 入力した管理者
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      # 売上発生日
      t.date    :sold_on, null: false
      # 販売先 enum（0=自販機1, 1=自販機2, 2=自販機3, 3=自販機4, 4=売店）
      t.integer :source,  null: false
      # 売上額（ウォン単位整数）
      t.integer :amount,  null: false
      # 特記事項
      t.text    :note

      t.timestamps
    end

    # 同じ日・同じ販売先の重複を防ぐ複合UNIQUEインデックス
    add_index :sales_records, [ :sold_on, :source ], unique: true
    add_index :sales_records, :sold_on
  end
end
