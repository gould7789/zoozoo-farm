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
end
