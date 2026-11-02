require "rails_helper"

RSpec.describe ExpenseRecord, type: :model do
  describe "검증" do
    it { is_expected.to validate_presence_of(:spent_on) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(9_999_999) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe "연관" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "enum" do
    it "category enum 이 올바르게 정의돼 있다" do
      expect(ExpenseRecord.categories).to eq({
        "animal_purchase" => 0,
        "food"            => 1,
        "medical"         => 2,
        "disposal"        => 3,
        "maintenance"     => 4,
        "other"           => 5
      })
    end
  end

  describe "스코프" do
    it ".recent 는 spent_on 내림차순으로 반환한다" do
      user  = create(:user)
      older = create(:expense_record, created_by: user, spent_on: 3.days.ago, category: :food)
      newer = create(:expense_record, created_by: user, spent_on: Date.today,  category: :medical)

      expect(ExpenseRecord.recent.first).to eq(newer)
      expect(ExpenseRecord.recent.last).to eq(older)
    end
  end

  describe ".in_month" do
    let(:user) { create(:user) }

    it "지정한 연월의 레코드만 반환한다" do
      target = create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 15))
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 5, 15))

      expect(ExpenseRecord.in_month(2026, 4)).to contain_exactly(target)
    end

    it "전월 말일과 다음달 1일 레코드는 넣지 않는다" do
      # 월 경계 — 범위 조건의 끝이 맞는지 확인한다
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 3, 31))
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 5, 1))
      first_day = create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 1))
      last_day  = create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 30))

      expect(ExpenseRecord.in_month(2026, 4)).to contain_exactly(first_day, last_day)
    end
  end

  describe ".available_year_months" do
    let(:user) { create(:user) }

    it "기록이 있는 연월을 최신순으로 반환한다" do
      create(:expense_record, created_by: user, spent_on: Date.new(2025, 12, 3))
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 15))
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 1, 20))

      expect(ExpenseRecord.available_year_months).to eq([ [ 2026, 4 ], [ 2026, 1 ], [ 2025, 12 ] ])
    end

    it "같은 월의 여러 레코드는 1건으로 묶는다" do
      # 지출은 UNIQUE 제약이 없어 같은 날 같은 종류도 여러 건 넣을 수 있다
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 1),  category: :food)
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 1),  category: :food)
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 30), category: :medical)

      expect(ExpenseRecord.available_year_months).to eq([ [ 2026, 4 ] ])
    end

    it "레코드가 없으면 빈 배열을 반환한다" do
      expect(ExpenseRecord.available_year_months).to eq([])
    end
  end

  describe "DB 제약" do
    it_behaves_like "DB 가 범위 밖 enum 값을 거부한다", :category, 9
  end
end
