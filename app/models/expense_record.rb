# 支出記録モデル — Admin専用、日次支出データを管理する
class ExpenseRecord < ApplicationRecord
  # 入力した管理者
  belongs_to :created_by, class_name: "User"

  # 支出種類 enum（0=動物購入費, 1=餌代, 2=医療費, 3=死骸処理費, 4=施設維持費, 5=その他）
  enum :category, {
    animal_purchase: 0,
    food:            1,
    medical:         2,
    disposal:        3,
    maintenance:     4,
    other:           5
  }

  # 支出発生日・種類・金額・内容は必須
  validates :spent_on,    presence: true
  validates :category,    presence: true
  validates :amount,      presence: true,
                          numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :description, presence: true

  # 最新の支出日順に並べるスコープ
  scope :recent, -> { order(spent_on: :desc) }
end
