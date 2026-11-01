# AnimalCategory 테스트 데이터
FactoryBot.define do
  factory :animal_category do
    zone
    sequence(:name) { |n| "카테고리#{n}" }
  end
end
