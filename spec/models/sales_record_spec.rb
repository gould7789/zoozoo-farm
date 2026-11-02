require "rails_helper"

RSpec.describe SalesRecord, type: :model do
  describe "검증" do
    it { is_expected.to validate_presence_of(:sold_on) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(9_999_999) }

    it "같은 sold_on 과 source 조합은 저장할 수 없다" do
      user = create(:user)
      create(:sales_record, created_by: user, sold_on: Date.today, source: :vending_1)
      duplicate = build(:sales_record, created_by: user, sold_on: Date.today, source: :vending_1)
      expect(duplicate).not_to be_valid
    end
  end

  describe "연관" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "enum" do
    it "source enum 이 올바르게 정의돼 있다" do
      expect(SalesRecord.sources).to eq({
        "vending_1" => 0,
        "vending_2" => 1,
        "vending_3" => 2,
        "vending_4" => 3,
        "stall"     => 4
      })
    end
  end

  describe "스코프" do
    it ".recent 는 sold_on 내림차순으로 반환한다" do
      user  = create(:user)
      older = create(:sales_record, created_by: user, sold_on: 3.days.ago, source: :vending_1)
      newer = create(:sales_record, created_by: user, sold_on: Date.today,  source: :vending_2)

      expect(SalesRecord.recent.first).to eq(newer)
      expect(SalesRecord.recent.last).to eq(older)
    end
  end

  describe ".in_month" do
    let(:user) { create(:user) }

    it "지정한 연월의 레코드만 반환한다" do
      target = create(:sales_record, created_by: user, sold_on: Date.new(2026, 4, 15), source: :vending_1)
      create(:sales_record, created_by: user, sold_on: Date.new(2026, 5, 15), source: :vending_2)

      expect(SalesRecord.in_month(2026, 4)).to contain_exactly(target)
    end

    it "전월 말일과 다음달 1일 레코드는 넣지 않는다" do
      # 월 경계 — 범위 조건의 끝이 맞는지 확인한다
      create(:sales_record, created_by: user, sold_on: Date.new(2026, 3, 31), source: :vending_1)
      create(:sales_record, created_by: user, sold_on: Date.new(2026, 5, 1),  source: :vending_2)
      first_day = create(:sales_record, created_by: user, sold_on: Date.new(2026, 4, 1),  source: :vending_3)
      last_day  = create(:sales_record, created_by: user, sold_on: Date.new(2026, 4, 30), source: :vending_4)

      expect(SalesRecord.in_month(2026, 4)).to contain_exactly(first_day, last_day)
    end
  end

  describe ".available_year_months" do
    let(:user) { create(:user) }

    it "기록이 있는 연월을 최신순으로 반환한다" do
      create(:sales_record, created_by: user, sold_on: Date.new(2025, 12, 3), source: :vending_1)
      create(:sales_record, created_by: user, sold_on: Date.new(2026, 4, 15), source: :vending_2)
      create(:sales_record, created_by: user, sold_on: Date.new(2026, 1, 20), source: :vending_3)

      expect(SalesRecord.available_year_months).to eq([ [ 2026, 4 ], [ 2026, 1 ], [ 2025, 12 ] ])
    end

    it "같은 월의 여러 레코드는 1건으로 묶는다" do
      create(:sales_record, created_by: user, sold_on: Date.new(2026, 4, 1),  source: :vending_1)
      create(:sales_record, created_by: user, sold_on: Date.new(2026, 4, 15), source: :vending_2)
      create(:sales_record, created_by: user, sold_on: Date.new(2026, 4, 30), source: :vending_3)

      expect(SalesRecord.available_year_months).to eq([ [ 2026, 4 ] ])
    end

    it "레코드가 없으면 빈 배열을 반환한다" do
      expect(SalesRecord.available_year_months).to eq([])
    end
  end

  describe "DB 제약" do
    it_behaves_like "DB 가 범위 밖 enum 값을 거부한다", :source, 9, "chk_sales_source"
  end
end
