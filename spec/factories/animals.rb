# Animalのテストデータファクトリ
# nameはNULL許容のため省略、genderはデフォルトのunknownを明示
FactoryBot.define do
  factory :animal do
    zone                      # 館との関連を自動生成
    species { "インコ" }
    name    { nil }           # 個体名は任意 — 多頭飼育種を想定
    gender  { :unknown }
    active  { true }
  end
end
