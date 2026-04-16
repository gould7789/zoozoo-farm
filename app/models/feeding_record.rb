# 給餌記録モデル — 動物ごとの日々の給餌データを管理する
class FeedingRecord < ApplicationRecord
  # 対象動物（動物はactive=falseで論理削除）
  belongs_to :animal
  # 作成者
  belongs_to :created_by, class_name: "User"

  # 給餌日時・餌の種類は必須
  validates :fed_at,    presence: true
  validates :food_type, presence: true
  # 給餌量は0以上の整数
  validates :amount_g, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 99_999 }, allow_nil: true

  # 最新の給餌日時順に並べるスコープ
  scope :recent, -> { order(fed_at: :desc) }
end
