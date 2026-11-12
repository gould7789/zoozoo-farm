# 건강 기록 모델 — 개체별 일일 건강 관찰 데이터
# created_by 는 권한 체크와 감사 추적에 쓴다
class HealthRecord < ApplicationRecord
  # 동물은 논리 삭제라 belongs_to 가 끊기지 않는다
  belongs_to :animal
  belongs_to :created_by, class_name: "User"

  enum :condition, { normal: 0, caution: 1, danger: 2 }

  validates :recorded_on, presence: true
  validates :weight_kg, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 9_999.99 }, allow_nil: true

  # recorded_on 은 date 라 하루에 두 번 적으면 동률이 난다.
  # 동률의 순서는 SQL 에서 미정의라 조회마다 갈릴 수 있어 created_at 으로 끊는다
  scope :recent, -> { order(recorded_on: :desc, created_at: :desc) }
end
