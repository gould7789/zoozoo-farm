# AnimalCategoryのテストデータファクトリ
FactoryBot.define do
  factory :animal_category do
    zone
    sequence(:name) { |n| "カテゴリ#{n}" }
  end
end
