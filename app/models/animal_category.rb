# 동물 카테고리 모델
# 관 안에서 동물을 종류별로 묶는다 (예: 알파카, 토끼)
class AnimalCategory < ApplicationRecord
  belongs_to :zone
  # nullify — 카테고리를 지워도 동물은 남기고 animal_category_id만 NULL로 만든다.
  # 카테고리는 분류용이라 지울 수 있지만, 동물이 같이 사라지면 안 된다
  has_many :animals, foreign_key: :animal_category_id, dependent: :nullify

  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { scope: :zone_id, message: "이 관에 이미 같은 이름의 카테고리가 있습니다." }

  # 논리 삭제된 동물은 빼고 센다
  def total_count
    animals.active.sum(:individual_count)
  end
end
