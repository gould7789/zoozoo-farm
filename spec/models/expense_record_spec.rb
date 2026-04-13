# ExpenseRecordモデルのバリデーション・アソシエーション・スコープをテストする
require "rails_helper"

RSpec.describe ExpenseRecord, type: :model do
  describe "バリデーション" do
    # 支出発生日は必須
    it { should validate_presence_of(:spent_on) }
    # 支出種類は必須
    it { should validate_presence_of(:category) }
    # 支出額は必須
    it { should validate_presence_of(:amount) }
    # 支出額は0以上9999999以下の整数
    it { should validate_numericality_of(:amount).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(9_999_999) }
    # 支出内容は必須（監査対応）
    it { should validate_presence_of(:description) }
  end

  describe "アソシエーション" do
    # 作成者はcreated_byカラムでusersを参照する
    it { should belong_to(:created_by).class_name("User") }
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
    # 最新の支出日順に並べることで直近の支出を先頭に表示する
    it ".recentはspent_onの降順で返す" do
      user  = create(:user)
      older = create(:expense_record, created_by: user, spent_on: 3.days.ago, category: :food)
      newer = create(:expense_record, created_by: user, spent_on: Date.today,  category: :medical)

      expect(ExpenseRecord.recent.first).to eq(newer)
      expect(ExpenseRecord.recent.last).to eq(older)
    end
  end
end
