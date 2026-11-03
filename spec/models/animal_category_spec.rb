# AnimalCategory 모델의 검증·연관·메서드
require "rails_helper"

RSpec.describe AnimalCategory, type: :model do
  describe "검증" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }

    it "같은 관 안에서 같은 이름의 카테고리는 만들 수 없다" do
      zone = create(:zone)
      create(:animal_category, zone: zone, name: "알파카")
      duplicate = build(:animal_category, zone: zone, name: "알파카")
      expect(duplicate).not_to be_valid
    end

    it "다른 관이면 같은 이름의 카테고리를 만들 수 있다" do
      zone1 = create(:zone, name: "가관")
      zone2 = create(:zone, name: "나관")
      create(:animal_category, zone: zone1, name: "알파카")
      category2 = build(:animal_category, zone: zone2, name: "알파카")
      expect(category2).to be_valid
    end
  end

  describe "연관" do
    it { should belong_to(:zone) }
    it { should have_many(:animals).with_foreign_key(:animal_category_id) }
  end

  describe "#total_count" do
    it "active 동물의 individual_count 합계를 반환한다" do
      zone     = create(:zone)
      category = create(:animal_category, zone: zone)
      create(:animal, zone: zone, animal_category: category, individual_count: 10, active: true)
      create(:animal, :exited, zone: zone, animal_category: category, individual_count: 5)
      expect(category.total_count).to eq(10)
    end
  end

  describe "카테고리 삭제 시" do
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
