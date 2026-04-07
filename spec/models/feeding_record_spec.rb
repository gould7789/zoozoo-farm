# FeedingRecordモデルのバリデーション・アソシエーション・スコープをテストする
require "rails_helper"

RSpec.describe FeedingRecord, type: :model do
  describe "バリデーション" do
    # 給餌日時は必須
    it { should validate_presence_of(:fed_at) }
    # 餌の種類は必須
    it { should validate_presence_of(:food_type) }
    # 給餌量は0以上の整数（任意）
    it { should validate_numericality_of(:amount_g).only_integer.is_greater_than_or_equal_to(0).allow_nil }
  end

  describe "アソシエーション" do
    # 給餌記録は必ずどこかの動物に紐づく
    it { should belong_to(:animal) }
    # 作成者はcreated_byカラムでusersを参照する
    it { should belong_to(:created_by).class_name("User") }
  end

  describe "スコープ" do
    # 最新の給餌日時順に並べることで直近の給餌を先頭に表示する
    it ".recentは給餌日時の降順で返す" do
      animal = create(:animal)
      user   = create(:user)
      older  = create(:feeding_record, animal: animal, created_by: user, fed_at: 3.days.ago)
      newer  = create(:feeding_record, animal: animal, created_by: user, fed_at: 1.hour.ago)

      expect(FeedingRecord.recent.first).to eq(newer)
      expect(FeedingRecord.recent.last).to eq(older)
    end
  end
end
