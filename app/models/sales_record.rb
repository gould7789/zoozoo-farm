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

  # 指定した年月のレコードに絞る
  # EXTRACT(YEAR FROM ...)ではなく範囲条件を使う
  # — カラムに関数を適用するとインデックス(index_sales_records_on_sold_on)が効かないため
  scope :in_month, ->(year, month) {
    first_day = Date.new(year, month, 1)
    where(sold_on: first_day..first_day.end_of_month)
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
      .pluck(Arel.sql("date_trunc('month', sold_on)::date"))
      .sort
      .reverse
      .map { |d| [ d.year, d.month ] }
  end
end
