# ゾーンテーブルを作成するマイグレーション（シードデータで固定管理）
class CreateZones < ActiveRecord::Migration[8.1]
  def change
    create_table :zones do |t|
      t.string :name,        null: false, limit: 100
      t.text   :description

      t.timestamps
    end

    add_index :zones, :name, unique: true
  end
end
