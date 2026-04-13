# お知らせテーブルの作成マイグレーション
class CreateNotices < ActiveRecord::Migration[8.0]
  def change
    create_table :notices, id: :uuid do |t|
      # 作成者
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      # カテゴリ（0=全体, 1=コザクラ館, 2=オウム館, 3=爬虫類館, 4=ミニ動物館, 5=屋外体験館, 6=隔離室）
      t.integer :category, null: false, default: 0
      # お知らせ本文
      t.text :body, null: false

      t.timestamps
    end

    # カテゴリ・作成者での検索用インデックス
    add_index :notices, :category
  end
end
