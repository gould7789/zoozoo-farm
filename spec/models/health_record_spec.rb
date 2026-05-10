require "rails_helper"

RSpec.describe HealthRecord, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:recorded_on) }
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:animal) }
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "Enum" do
    it { is_expected.to define_enum_for(:condition).with_values(normal: 0, caution: 1, danger: 2) }
  end

  describe "デフォルト値" do
    it "conditionのデフォルトはnormal" do
      expect(HealthRecord.new.condition).to eq("normal")
    end
  end

  describe "スコープ" do
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
