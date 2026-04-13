# 健康記録モデル — 動物ごとの日々の健康観察データを管理する
# 作成者は権限チェックと監査追跡に使用する
class HealthRecord < ApplicationRecord
  # 対象動物（動物はactive=falseで論理削除）
  belongs_to :animal
  # 作成者
  belongs_to :created_by, class_name: "User"

  # コンディション: 0=normal, 1=caution, 2=danger
  enum :condition, { normal: 0, caution: 1, danger: 2 }

  # 観察日は必須
  validates :recorded_on, presence: true

  # 最新の観察日順に並べるスコープ
  scope :recent, -> { order(recorded_on: :desc) }
end
