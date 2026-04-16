# AnimalCategoryモデルのバリデーション・アソシエーション・メソッドをテストする
require "rails_helper"

RSpec.describe AnimalCategory, type: :model do
  describe "バリデーション" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }

    # 同じ館内でカテゴリ名の重複を禁止する
    it "같은 관 안에서 같은 이름의 카테고리는 만들 수 없다" do
      zone = create(:zone)
      create(:animal_category, zone: zone, name: "アルパカ")
      duplicate = build(:animal_category, zone: zone, name: "アルパカ")
      expect(duplicate).not_to be_valid
    end

    # 異なる館なら同名カテゴリを作成できる
    it "다른 관이면 같은 이름의 카테고리를 만들 수 있다" do
      zone1 = create(:zone, name: "館A")
      zone2 = create(:zone, name: "館B")
      create(:animal_category, zone: zone1, name: "アルパカ")
      category2 = build(:animal_category, zone: zone2, name: "アルパカ")
      expect(category2).to be_valid
    end
  end

  describe "アソシエーション" do
    it { should belong_to(:zone) }
    it { should have_many(:animals).with_foreign_key(:animal_category_id) }
  end

  describe "#total_count" do
    # アクティブな動物のindividual_countの合計を返す
    it "active 동물의 individual_count 합계를 반환한다" do
      zone     = create(:zone)
      category = create(:animal_category, zone: zone)
      create(:animal, zone: zone, animal_category: category, individual_count: 10, active: true)
      create(:animal, zone: zone, animal_category: category, individual_count: 5,  active: false)
      expect(category.total_count).to eq(10)
    end
  end

  describe "カテゴリ削除時" do
    # カテゴリを削除しても所属動物は削除されず、animal_category_idがNULLになる
    it "카테고리를 삭제해도 동물은 삭제되지 않고 미분류로 이동된다" do
      zone     = create(:zone)
      category = create(:animal_category, zone: zone)
      animal   = create(:animal, zone: zone, animal_category: category)
      category.destroy!
      expect(Animal.find(animal.id)).to be_present
      expect(animal.reload.animal_category_id).to be_nil
    end
  end
end
