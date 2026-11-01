# 매출 기록 모델 — Admin 전용, 일별 매출 데이터
class SalesRecord < ApplicationRecord
  belongs_to :created_by, class_name: "User"

  enum :source, {
    vending_1: 0,
    vending_2: 1,
    vending_3: 2,
    vending_4: 3,
    stall:     4
  }

  validates :sold_on, presence: true
  validates :source,  presence: true
  validates :amount,  presence: true,
                      numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9_999_999 }

  # 같은 날 같은 판매처가 두 번 들어가는 것을 막는다.
  # DB 에도 UNIQUE (sold_on, source) 가 걸려 있다 — 이게 있어야
  # "입력 누락"과 "진짜 0원"을 구분할 수 있다
  validates :source, uniqueness: { scope: :sold_on }

  scope :recent, -> { order(sold_on: :desc) }

  # 지정한 연월로 좁힌다.
  # EXTRACT(YEAR FROM ...) 가 아니라 범위 조건을 쓰는 이유는, 컬럼에 함수를 씌우면
  # 인덱스(index_sales_records_on_sold_on)가 먹지 않기 때문이다
  scope :in_month, ->(year, month) {
    first_day = Date.new(year, month, 1)
    where(sold_on: first_day..first_day.end_of_month)
  }

  # 기록이 있는 연월을 최신순으로 — [[2026, 8], [2026, 7], ...]
  #   date_trunc    PostgreSQL 고유 함수. 날짜를 월 단위로 자른다
  #   reorder(nil)  정렬이 붙은 릴레이션이면 SELECT DISTINCT 와 ORDER BY 가 충돌한다
  # 정렬은 Ruby 에서 한다 — 월 수만큼의 작은 배열이다
  def self.available_year_months
    reorder(nil)
      .distinct
      .pluck(Arel.sql("date_trunc('month', sold_on)::date"))
      .sort
      .reverse
      .map { |d| [ d.year, d.month ] }
  end
end
