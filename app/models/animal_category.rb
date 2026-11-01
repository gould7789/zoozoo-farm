# 動物カテゴリモデル
# 館内で動物を種類別にグループ分けする（例: アルパカ、ウサギ）
class AnimalCategory < ApplicationRecord
  belongs_to :zone
  # カテゴリ削除時は動物のcategory_idをNULLにする（動物は削除しない）
  has_many :animals, foreign_key: :animal_category_id, dependent: :nullify

  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { scope: :zone_id, message: "이 관에 이미 같은 이름의 카테고리가 있습니다." }

  # 所属するアクティブ動物のindividual_countの合計を返す
  def total_count
    animals.active.sum(:individual_count)
  end
end
