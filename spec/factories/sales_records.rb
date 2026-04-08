# 売上記録のテストデータファクトリー
FactoryBot.define do
  factory :sales_record do
    # 入力した管理者
    association :created_by, factory: :user
    # 売上発生日（デフォルトは今日）
    sold_on { Date.today }
    # 販売先（デフォルトは自販機1）
    source  { :vending_1 }
    # 売上額（デフォルトは1000ウォン）
    amount  { 1000 }
    note    { nil }
  end
end
