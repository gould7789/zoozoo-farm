require "rails_helper"

RSpec.describe Animal, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:species) }
    it { is_expected.to validate_length_of(:species).is_at_most(100) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_numericality_of(:individual_count).only_integer.is_greater_than_or_equal_to(1) }
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:zone) }
    it { is_expected.to belong_to(:animal_category).optional }
  end

  describe "Enum" do
    it { is_expected.to define_enum_for(:gender).with_values(male: 0, female: 1, unknown: 2) }
    it { is_expected.to define_enum_for(:cites_grade).with_values(none: 0, grade_i: 1, grade_ii: 2, grade_iii: 3).with_prefix(:cites) }
  end

  describe "デフォルト値" do
    subject(:animal) { Animal.new }

    it "genderのデフォルトはunknown" do
      expect(animal.gender).to eq("unknown")
    end

    it "cites_gradeのデフォルトはnone" do
      expect(animal.cites_grade).to eq("none")
    end

    it "activeのデフォルトはtrue" do
      expect(animal.active).to be true
    end

    it "individual_countのデフォルトは1" do
      expect(animal.individual_count).to eq(1)
    end
  end

  describe "スコープ" do
    it ".activeは論理削除されていない動物のみ返す" do
      zone = Zone.create!(name: "テスト館")
      active_animal   = Animal.create!(zone: zone, species: "インコ", active: true)
      inactive_animal = Animal.create!(zone: zone, species: "オウム", active: false)

      expect(Animal.active).to include(active_animal)
      expect(Animal.active).not_to include(inactive_animal)
    end

    describe ".with_alert_condition" do
      let(:user) { create(:user) }

      it "最新の健康記録がcautionの動物を返す" do
        animal = create(:animal)
        create(:health_record, animal: animal, created_by: user, condition: :caution, recorded_on: Date.today)

        expect(Animal.with_alert_condition).to include(animal)
      end

      it "最新の健康記録がdangerの動物を返す" do
        animal = create(:animal)
        create(:health_record, animal: animal, created_by: user, condition: :danger, recorded_on: Date.today)

        expect(Animal.with_alert_condition).to include(animal)
      end

      it "最新の健康記録がnormalの動物は返さない" do
        animal = create(:animal)
        create(:health_record, animal: animal, created_by: user, condition: :normal, recorded_on: Date.today)

        expect(Animal.with_alert_condition).not_to include(animal)
      end

      it "健康記録がない動物は返さない" do
        animal = create(:animal)

        expect(Animal.with_alert_condition).not_to include(animal)
      end

      it "古い記録がcautionでも最新記録がnormalなら返さない" do
        animal = create(:animal)
        create(:health_record, animal: animal, created_by: user, condition: :caution, recorded_on: 3.days.ago)
        create(:health_record, animal: animal, created_by: user, condition: :normal,  recorded_on: Date.today)

        expect(Animal.with_alert_condition).not_to include(animal)
      end

      it "古い記録がnormalでも最新記録がdangerなら返す" do
        animal = create(:animal)
        create(:health_record, animal: animal, created_by: user, condition: :normal, recorded_on: 3.days.ago)
        create(:health_record, animal: animal, created_by: user, condition: :danger, recorded_on: Date.today)

        expect(Animal.with_alert_condition).to include(animal)
      end

      it "active=falseの動物は返さない" do
        animal = create(:animal, active: false)
        create(:health_record, animal: animal, created_by: user, condition: :danger, recorded_on: Date.today)

        expect(Animal.with_alert_condition).not_to include(animal)
      end
    end
  end
end
