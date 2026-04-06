# ゾーンテーブルを作成するマイグレーション
class CreateZones < ActiveRecord::Migration[8.1]
  def change
    create_table :zones do |t|
      t.string :name,        null: false, limit: 100  # 館名（例: 사랑새관）— UNIQUEインデックスで重複防止
      t.text   :description                            # 館の説明（任意）

      t.timestamps
    end

    # 館名は一意である必要があるためUNIQUEインデックスを追加
    add_index :zones, :name, unique: true
  end
end
