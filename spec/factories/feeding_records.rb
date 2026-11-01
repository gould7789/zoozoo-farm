# FeedingRecord 테스트 데이터
FactoryBot.define do
  factory :feeding_record do
    animal
    association :created_by, factory: :user
    fed_at    { Time.current }
    food_type { "펠렛" }
    amount_g  { nil }
    note      { nil }
  end
end
