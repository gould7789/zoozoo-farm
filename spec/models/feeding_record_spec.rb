require "rails_helper"

RSpec.describe FeedingRecord, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:fed_at) }
    it { is_expected.to validate_presence_of(:food_type) }
    it { is_expected.to validate_numericality_of(:amount_g).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(99_999).allow_nil }
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:animal) }
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "スコープ" do
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
