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
                          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9_999_999 }
  validates :description, presence: true

  # 最新の支出日順に並べるスコープ
  scope :recent, -> { order(spent_on: :desc) }

  # 指定した年月のレコードに絞る
  # EXTRACT(YEAR FROM ...)ではなく範囲条件を使う
  # — カラムに関数を適用するとインデックス(index_expense_records_on_spent_on)が効かないため
  scope :in_month, ->(year, month) {
    first_day = Date.new(year, month, 1)
    where(spent_on: first_day..first_day.end_of_month)
  }

  # 記録が存在する年月を新しい順で返す → [[2026, 8], [2026, 7], ...]
  # 全件をRubyに読み込まず、月単位に丸めた重複なしの日付だけを取得する
  # date_truncはPostgreSQL固有の関数
  # reorder(nil) — 並び順が付いたリレーションから呼ばれると
  #   SELECT DISTINCT と ORDER BY が衝突してPostgreSQLがエラーを返すため
  # 並べ替えはRuby側で行う（月数分の小さな配列）
  def self.available_year_months
    reorder(nil)
      .distinct
      .pluck(Arel.sql("date_trunc('month', spent_on)::date"))
      .sort
      .reverse
      .map { |d| [ d.year, d.month ] }
  end
end
