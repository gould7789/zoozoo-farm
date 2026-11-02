# enum 의 값 범위를 DB 에도 내린다.
#
# 모델에 enum 이 있어도 update_all · insert_all · 생SQL · 백필은 모델 검증을
# 지나지 않는다. 예외도 경고도 없이 범위 밖 값이 들어간다.
# 금액에 CHECK 를 건 것과 같은 판단이다 (chk_sales_amount, chk_expense_amount).
#
# limit: 2 는 저장 폭일 뿐 범위를 제한하지 않는다 — smallint 는 -32768~32767 을
# 받는다. 범위는 CHECK 가 맡고, 둘은 서로를 대신하지 않는다.
#
# 운영 데이터에 위반 행이 없음을 Supabase 에서 먼저 확인했다(7개 컬럼 + NULL, 0건).
# 위반 행이 있으면 ADD CONSTRAINT 가 실패하고, buildCommand 의 db:migrate 가
# 떨어져 배포 자체가 멈춘다.
class AddEnumCheckConstraints < ActiveRecord::Migration[8.1]
  # smallint 로 좁힐 컬럼 — 나머지 enum 은 이미 limit: 2 다
  NARROW = {
    expense_records: :category,
    health_records:  :condition,
    notices:         :category,
    sales_records:   :source
  }.freeze

  # 컬럼마다 허용하는 값.
  # position 은 NULL 을 받는다(Staff 는 직급이 없다). 따로 적지 않아도 된다 —
  # CHECK 는 식이 FALSE 일 때만 거부하는데, NULL IN (0,1,2) 는 FALSE 가 아니라
  # NULL 로 평가되기 때문이다. NULL 을 막으려면 CHECK 가 아니라 NOT NULL 을 쓴다
  CONSTRAINTS = [
    [ :animals,         "gender IN (0,1,2)",                             "chk_animals_gender" ],
    [ :animals,         "cites_grade IN (0,1,2,3)",                      "chk_animals_cites_grade" ],
    [ :users,           "role IN (0,1)",                                 "chk_users_role" ],
    [ :users,           "position IN (0,1,2,3,4,5)",                     "chk_users_position" ],
    [ :notices,         "category IN (0,1,2,3,4,5,6)",                   "chk_notices_category" ],
    [ :expense_records, "category IN (0,1,2,3,4,5)",                     "chk_expense_category" ],
    [ :sales_records,   "source IN (0,1,2,3,4)",                         "chk_sales_source" ]
  ].freeze

  def up
    NARROW.each { |table, column| change_column table, column, :integer, limit: 2 }
    CONSTRAINTS.each { |table, expression, name| add_check_constraint table, expression, name: name }
  end

  def down
    CONSTRAINTS.each { |table, _expression, name| remove_check_constraint table, name: name }
    NARROW.each { |table, column| change_column table, column, :integer, limit: 4 }
  end
end
