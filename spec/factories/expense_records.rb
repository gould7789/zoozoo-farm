# 支出記録のテストデータファクトリー
FactoryBot.define do
  factory :expense_record do
    # 入力した管理者
    association :created_by, factory: :user
    # 支出発生日（デフォルトは今日）
    spent_on    { Date.today }
    # 支出種類（デフォルトは餌代）
    category    { :food }
    # 支出額（デフォルトは1000ウォン）
    amount      { 1000 }
    # 支出内容
    description { "먹이 구매" }
  end
end
