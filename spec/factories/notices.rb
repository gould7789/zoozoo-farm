# お知らせのテストデータファクトリー
FactoryBot.define do
  factory :notice do
    # 作成者
    association :created_by, factory: :user
    # カテゴリ（デフォルトは全体通知）
    category { :general }
    # 題名（一覧で内容を見分けるための見出し）
    title { "テストお知らせ" }
    # 本文（Action Textのリッチテキスト）
    content { "テストお知らせ本文" }
  end
end
