# Notice 테스트 데이터
FactoryBot.define do
  factory :notice do
    association :created_by, factory: :user
    category { :general }
    # 제목 — 목록에서 내용을 가르는 머리
    title { "테스트 공지" }
    content { "테스트 공지 본문" }
  end
end
