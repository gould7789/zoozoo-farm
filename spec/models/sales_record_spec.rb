# SalesRecordモデルのバリデーション・アソシエーション・スコープをテストする
require "rails_helper"

RSpec.describe SalesRecord, type: :model do
  describe "バリデーション" do
    # 売上発生日は必須
    it { should validate_presence_of(:sold_on) }
    # 販売先は必須
    it { should validate_presence_of(:source) }
    # 売上額は必須
    it { should validate_presence_of(:amount) }
    # 売上額は0以上の整数
    it { should validate_numericality_of(:amount).only_integer.is_greater_than_or_equal_to(0) }

    # 同じ日・同じ販売先の重複は不可（複合UNIQUE）
    it "同じsold_onとsourceの組み合わせは保存できない" do
      user = create(:user)
      create(:sales_record, created_by: user, sold_on: Date.today, source: :vending_1)
      duplicate = build(:sales_record, created_by: user, sold_on: Date.today, source: :vending_1)
      expect(duplicate).not_to be_valid
    end
  end

  describe "アソシエーション" do
    # 作成者はcreated_byカラムでusersを参照する
    it { should belong_to(:created_by).class_name("User") }
  end

  describe "enum" do
    it "sourceのenumが正しく定義されている" do
      expect(SalesRecord.sources).to eq({
        "vending_1" => 0,
        "vending_2" => 1,
        "vending_3" => 2,
        "vending_4" => 3,
        "stall"     => 4
      })
    end
  end

  describe "スコープ" do
    # 最新の売上日順に並べることで直近の売上を先頭に表示する
    it ".recentはsold_onの降順で返す" do
      user   = create(:user)
      older  = create(:sales_record, created_by: user, sold_on: 3.days.ago, source: :vending_1)
      newer  = create(:sales_record, created_by: user, sold_on: Date.today,  source: :vending_2)

      expect(SalesRecord.recent.first).to eq(newer)
      expect(SalesRecord.recent.last).to eq(older)
    end
  end
end
