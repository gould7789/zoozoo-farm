# Zoneのテストデータファクトリ
# sequenceで連番の館名を生成 — 一意制約に対応
FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "Zone #{n}" }
    description { nil }
  end
end
