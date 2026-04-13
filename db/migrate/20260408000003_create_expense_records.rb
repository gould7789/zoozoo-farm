# 支出記録テーブルの作成マイグレーション（Admin専用）
class CreateExpenseRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :expense_records, id: :uuid do |t|
      # 入力した管理者
      t.references :created_by,   null: false, foreign_key: { to_table: :users }, type: :uuid
      # 支出発生日
      t.date        :spent_on,    null: false
      # 支出種類 enum（0=動物購入費, 1=餌代, 2=医療費, 3=死骸処理費, 4=施設維持費, 5=その他）
      t.integer     :category,    null: false
      # 支出額（ウォン単位整数）
      t.integer     :amount,      null: false
      # 支出内容
      t.text        :description, null: false

      t.timestamps
    end

    add_index :expense_records, :spent_on
    add_index :expense_records, :category
    # created_by_idインデックスはt.referencesが自動生成するため不要
  end
end
