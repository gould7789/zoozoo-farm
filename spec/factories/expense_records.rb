# ExpenseRecord 테스트 데이터
FactoryBot.define do
  factory :expense_record do
    association :created_by, factory: :user
    spent_on    { Date.today }
    category    { :food }
    amount      { 1000 }
    description { "먹이 구매" }
  end
end
