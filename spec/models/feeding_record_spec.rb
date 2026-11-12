require "rails_helper"

RSpec.describe FeedingRecord, type: :model do
  describe "검증" do
    it { is_expected.to validate_presence_of(:fed_at) }
    it { is_expected.to validate_presence_of(:food_type) }
    it { is_expected.to validate_numericality_of(:amount_g).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(99_999).allow_nil }
  end

  describe "연관" do
    it { is_expected.to belong_to(:animal) }
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "스코프" do
    it ".recent 는 급여 일시 내림차순으로 반환한다" do
      animal = create(:animal)
      user   = create(:user)
      older  = create(:feeding_record, animal: animal, created_by: user, fed_at: 3.days.ago)
      newer  = create(:feeding_record, animal: animal, created_by: user, fed_at: 1.hour.ago)

      expect(FeedingRecord.recent.first).to eq(newer)
      expect(FeedingRecord.recent.last).to eq(older)
    end

    # 폼이 분 단위로 보내므로 같은 fed_at 이 실제로 나온다.
    # 동률의 순서는 SQL 에서 미정의다 (health_record_spec 에 같은 이유를 적었다)
    it ".recent 는 같은 일시 기록을 나중에 적은 것부터 반환한다" do
      animal = create(:animal)
      user   = create(:user)
      fed_at = Time.current.change(hour: 8, min: 20, sec: 0)
      first_written = create(:feeding_record, animal: animal, created_by: user,
                             fed_at: fed_at, created_at: fed_at + 1.minute)
      last_written  = create(:feeding_record, animal: animal, created_by: user,
                             fed_at: fed_at, created_at: fed_at + 30.minutes)

      expect(FeedingRecord.recent.to_a).to eq([ last_written, first_written ])
    end
  end
end
