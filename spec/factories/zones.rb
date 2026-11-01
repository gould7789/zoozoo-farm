# Zone 테스트 데이터
# sequence 로 연번 관 이름을 만든다 — UNIQUE 제약 때문
FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "Zone #{n}" }
    description { nil }
  end
end
