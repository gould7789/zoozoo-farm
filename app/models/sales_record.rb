# 売上記録モデル — Admin専用、日次売上データを管理する
class SalesRecord < ApplicationRecord
  # 入力した管理者
  belongs_to :created_by, class_name: "User"

  # 販売先 enum（0=自販機1, 1=自販機2, 2=自販機3, 3=自販機4, 4=売店）
  enum :source, {
    vending_1: 0,
    vending_2: 1,
    vending_3: 2,
    vending_4: 3,
    stall:     4
  }

  # 売上発生日・販売先・売上額は必須
  validates :sold_on, presence: true
  validates :source,  presence: true
  validates :amount,  presence: true,
                      numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9_999_999 }

  # 同じ日・同じ販売先の重複を防ぐ
  validates :source, uniqueness: { scope: :sold_on }

  # 最新の売上日順に並べるスコープ
  scope :recent, -> { order(sold_on: :desc) }
end
