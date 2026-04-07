# HealthRecordモデルのバリデーション・アソシエーション・enum・スコープをテストする
require "rails_helper"

RSpec.describe HealthRecord, type: :model do
  describe "バリデーション" do
    # 観察日は必須（created_atと分離して実際の観察日を記録する）
    it { should validate_presence_of(:recorded_on) }
  end

  describe "アソシエーション" do
    # 健康記録は必ずどこかの動物に紐づく
    it { should belong_to(:animal) }
    # 作成者はcreated_byカラムでusersを参照する
    it { should belong_to(:created_by).class_name("User") }
  end

  describe "Enum" do
    # condition: 0=normal, 1=caution, 2=danger
    it { should define_enum_for(:condition).with_values(normal: 0, caution: 1, danger: 2) }
  end

  describe "デフォルト値" do
    subject(:health_record) { HealthRecord.new }

    # 特異事項がない限りは正常をデフォルトにする
    it "conditionのデフォルトはnormal" do
      expect(health_record.condition).to eq("normal")
    end
  end

  describe "スコープ" do
    # 最新の観察日順に並べることで直近の状態を先頭に表示する
    it ".recentは観察日の降順で返す" do
      animal = create(:animal)
      user   = create(:user)
      older  = create(:health_record, animal: animal, created_by: user, recorded_on: 3.days.ago)
      newer  = create(:health_record, animal: animal, created_by: user, recorded_on: Date.today)

      expect(HealthRecord.recent.first).to eq(newer)
      expect(HealthRecord.recent.last).to eq(older)
    end
  end
end
