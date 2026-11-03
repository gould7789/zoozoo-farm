# Animal 테스트 데이터
# name 은 NULL 허용이라 생략, gender 는 기본값 unknown 을 명시한다
FactoryBot.define do
  factory :animal do
    zone
    species          { "앵무새" }
    name             { nil }      # 개체명은 선택 — 여러 마리를 함께 기르는 종을 상정
    gender           { :unknown }
    active           { true }
    individual_count { 1 }
    animal_category  { nil }

    # 내보낸 개체 — CHECK 제약이 active 와 exit_reason 을 함께 보므로 셋을 같이 준다
    trait :exited do
      active      { false }
      exit_reason { :deceased }
      exited_on   { Date.new(2026, 3, 14) }
    end
  end
end
