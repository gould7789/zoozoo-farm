# お知らせのテストデータファクトリー
FactoryBot.define do
  factory :notice do
    # 作成者
    association :created_by, factory: :user
    # カテゴリ（デフォルトは全体通知）
    category { :general }
    # お知らせ本文
    body { "テストお知らせ本文" }
  end
end
