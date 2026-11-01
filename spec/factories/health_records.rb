# HealthRecord 테스트 데이터
FactoryBot.define do
  factory :health_record do
    animal
    association :created_by, factory: :user
    recorded_on { Date.today }
    condition   { :normal }
    weight_kg   { nil }
    note        { nil }
  end
end
