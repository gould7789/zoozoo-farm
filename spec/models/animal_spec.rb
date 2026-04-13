# Animalモデルのバリデーション・アソシエーション・enum・デフォルト値・スコープをテストする
require "rails_helper"

RSpec.describe Animal, type: :model do
  describe "バリデーション" do
    # 種名は必須（個体名はNULL許容）
    it { should validate_presence_of(:species) }
    it { should validate_length_of(:species).is_at_most(100) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe "アソシエーション" do
    # 動物は必ずどこかの館に所属する
    it { should belong_to(:zone) }
  end

  describe "Enum" do
    # gender: 0=male, 1=female, 2=unknown
    it { should define_enum_for(:gender).with_values(male: 0, female: 1, unknown: 2) }
    # cites_grade: 0=none, 1=I, 2=II, 3=III — prefixでARのnone?メソッドとの衝突を回避
    it { should define_enum_for(:cites_grade).with_values(none: 0, grade_i: 1, grade_ii: 2, grade_iii: 3).with_prefix(:cites) }
  end

  describe "デフォルト値" do
    subject(:animal) { Animal.new }

    # 性別不明をデフォルトにする（入手時に性別が確認できないケースが多いため）
    it "genderのデフォルトはunknown" do
      expect(animal.gender).to eq("unknown")
    end

    # CITES登録なしをデフォルトにする
    it "cites_gradeのデフォルトはnone" do
      expect(animal.cites_grade).to eq("none")
    end

    # 新規登録時は必ず有効状態
    it "activeのデフォルトはtrue" do
      expect(animal.active).to be true
    end
  end

  describe "スコープ" do
    # active=falseの動物（死亡・放出）はスコープから除外されることを確認
    it ".activeは論理削除されていない動物のみ返す" do
      zone = Zone.create!(name: "テスト館")
      active_animal   = Animal.create!(zone: zone, species: "インコ", active: true)
      inactive_animal = Animal.create!(zone: zone, species: "オウム", active: false)

      expect(Animal.active).to include(active_animal)
      expect(Animal.active).not_to include(inactive_animal)
    end
  end
end
