require "rails_helper"

RSpec.describe Notice, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_presence_of(:category) }
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
  end

  describe "enum" do
    it "categoryのenumが正しく定義されている" do
      expect(Notice.categories).to eq({
        "general"      => 0,
        "lovebird"     => 1,
        "parrot"       => 2,
        "reptile"      => 3,
        "small_animal" => 4,
        "outdoor"      => 5,
        "isolation"    => 6
      })
    end
  end

  describe "スコープ" do
    it ".recentは作成日時の降順で返す" do
      user  = create(:user)
      older = create(:notice, created_by: user, created_at: 2.days.ago)
      newer = create(:notice, created_by: user, created_at: 1.hour.ago)

      expect(Notice.recent.first).to eq(newer)
      expect(Notice.recent.last).to eq(older)
    end
  end
end
