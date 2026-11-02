require "rails_helper"

RSpec.describe HealthRecord, type: :model do
  describe "검증" do
    it { is_expected.to validate_presence_of(:recorded_on) }
  end

  describe "연관" do
    it { is_expected.to belong_to(:animal) }
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "Enum" do
    it { is_expected.to define_enum_for(:condition).with_values(normal: 0, caution: 1, danger: 2) }
  end

  describe "기본값" do
    it "condition 의 기본값은 normal" do
      expect(HealthRecord.new.condition).to eq("normal")
    end
  end

  describe "스코프" do
    it ".recent 는 관찰일 내림차순으로 반환한다" do
      animal = create(:animal)
      user   = create(:user)
      older  = create(:health_record, animal: animal, created_by: user, recorded_on: 3.days.ago)
      newer  = create(:health_record, animal: animal, created_by: user, recorded_on: Date.today)

      expect(HealthRecord.recent.first).to eq(newer)
      expect(HealthRecord.recent.last).to eq(older)
    end
  end

  describe "DB 제약" do
    it_behaves_like "DB 가 범위 밖 enum 값을 거부한다", :condition, 9, "chk_health_condition"
  end
end
