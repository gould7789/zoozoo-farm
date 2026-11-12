# 먹이 급여 기록 모델 — 개체별 일일 급여 데이터
class FeedingRecord < ApplicationRecord
  # 동물은 논리 삭제라 belongs_to 가 끊기지 않는다
  belongs_to :animal
  belongs_to :created_by, class_name: "User"

  validates :fed_at,    presence: true
  validates :food_type, presence: true
  validates :amount_g, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 99_999 }, allow_nil: true

  # 폼이 분 단위로 보내므로 같은 fed_at 이 나온다 (health_record.rb 와 같은 이유)
  scope :recent, -> { order(fed_at: :desc, created_at: :desc) }
end
