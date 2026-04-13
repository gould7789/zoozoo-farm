# 健康記録のテストデータファクトリー
FactoryBot.define do
  factory :health_record do
    # 対象動物（自動的にzoneも生成される）
    animal
    # 作成者
    association :created_by, factory: :user
    # 実際の観察日（今日の日付をデフォルトに）
    recorded_on { Date.today }
    # コンディションのデフォルトは正常
    condition   { :normal }
    weight_kg   { nil }
    note        { nil }
  end
end
