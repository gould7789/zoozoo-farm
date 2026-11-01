# SalesRecord 테스트 데이터
FactoryBot.define do
  factory :sales_record do
    association :created_by, factory: :user
    sold_on { Date.today }
    source  { :vending_1 }
    amount  { 1000 }
    note    { nil }
  end
end
