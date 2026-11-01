# 健康記録モデル — 動物ごとの日々の健康観察データを管理する
# 作成者は権限チェックと監査追跡に使用する
class HealthRecord < ApplicationRecord
  # 対象動物（動物はactive=falseで論理削除）
  belongs_to :animal
  belongs_to :created_by, class_name: "User"

  enum :condition, { normal: 0, caution: 1, danger: 2 }

  validates :recorded_on, presence: true
  validates :weight_kg, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 9_999.99 }, allow_nil: true

  scope :recent, -> { order(recorded_on: :desc) }
end
