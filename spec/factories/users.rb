# ユーザーのテストデータファクトリ
FactoryBot.define do
  factory :user do
    email    { Faker::Internet.unique.email }
    password { "password123" }
    name     { Faker::Name.name }
    role     { :staff }
    active   { true }

    # Admin ユーザーを生成するトレイト
    trait :admin do
      role { :admin }
    end

    # 退職済みユーザーを生成するトレイト
    trait :inactive do
      active { false }
    end
  end
end
