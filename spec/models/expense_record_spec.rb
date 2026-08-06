require "rails_helper"

RSpec.describe ExpenseRecord, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:spent_on) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(9_999_999) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "enum" do
    it "categoryのenumが正しく定義されている" do
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

  describe "スコープ" do
    it ".recentはspent_onの降順で返す" do
      user  = create(:user)
      older = create(:expense_record, created_by: user, spent_on: 3.days.ago, category: :food)
      newer = create(:expense_record, created_by: user, spent_on: Date.today,  category: :medical)

      expect(ExpenseRecord.recent.first).to eq(newer)
      expect(ExpenseRecord.recent.last).to eq(older)
    end
  end

  describe ".in_month" do
    let(:user) { create(:user) }

    it "指定した年月のレコードだけを返す" do
      target = create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 15))
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 5, 15))

      expect(ExpenseRecord.in_month(2026, 4)).to contain_exactly(target)
    end

    it "前月末日・翌月初日のレコードは含まない" do
      # 月境界 — 範囲条件の端が正しいかを確認する
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 3, 31))
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 5, 1))
      first_day = create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 1))
      last_day  = create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 30))

      expect(ExpenseRecord.in_month(2026, 4)).to contain_exactly(first_day, last_day)
    end
  end

  describe ".available_year_months" do
    let(:user) { create(:user) }

    it "記録が存在する年月を新しい順で返す" do
      create(:expense_record, created_by: user, spent_on: Date.new(2025, 12, 3))
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 15))
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 1, 20))

      expect(ExpenseRecord.available_year_months).to eq([ [ 2026, 4 ], [ 2026, 1 ], [ 2025, 12 ] ])
    end

    it "同じ月の複数レコードは1件にまとめる" do
      # 支出はUNIQUE制約がないため同じ日・同じ種類でも複数件登録できる
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 1),  category: :food)
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 1),  category: :food)
      create(:expense_record, created_by: user, spent_on: Date.new(2026, 4, 30), category: :medical)

      expect(ExpenseRecord.available_year_months).to eq([ [ 2026, 4 ] ])
    end

    it "レコードがない場合は空配列を返す" do
      expect(ExpenseRecord.available_year_months).to eq([])
    end
  end
end
