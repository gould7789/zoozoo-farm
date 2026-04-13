# 給餌記録のテストデータファクトリー
FactoryBot.define do
  factory :feeding_record do
    # 対象動物（自動的にzoneも生成される）
    animal
    # 作成者
    association :created_by, factory: :user
    # 給餌日時（デフォルトは現在時刻）
    fed_at    { Time.current }
    # 餌の種類（デフォルトはペレット）
    food_type { "ペレット" }
    amount_g  { nil }
    note      { nil }
  end
end
