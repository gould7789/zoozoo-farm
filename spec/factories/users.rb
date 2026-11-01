# User 테스트 데이터
FactoryBot.define do
  factory :user do
    email    { Faker::Internet.unique.email }
    password { "password123" }
    name     { Faker::Name.name }
    role     { :staff }
    active   { true }

    # Admin 사용자
    trait :admin do
      role { :admin }
    end

    # 퇴사 처리된 사용자
    trait :inactive do
      active { false }
    end
  end
end
