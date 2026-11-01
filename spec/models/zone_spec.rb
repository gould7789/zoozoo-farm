# Zone 모델의 검증과 연관
require "rails_helper"

RSpec.describe Zone, type: :model do
  # uniqueness 검증용 subject — 영문자를 포함한 유효한 이름이 필요하다
  subject { Zone.new(name: "Zone A") }

  describe "검증" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe "연관" do
    # 동물이 붙어 있는 관은 삭제할 수 없다 (논리 삭제만 허용하는 설계)
    it { should have_many(:animals).dependent(:restrict_with_error) }
    it { should have_many(:animal_categories).dependent(:destroy) }
  end
end
