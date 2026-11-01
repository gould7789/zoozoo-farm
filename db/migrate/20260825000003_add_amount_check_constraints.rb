# 금액에 음수가 들어가지 않도록 DB 에도 CHECK 제약을 건다
#
# 모델에 이미 numericality: { greater_than_or_equal_to: 0 } 가 있지만
# update_all · insert_all · 생SQL · 백필은 모델 검증을 지나지 않는다.
# 매출과 지출은 감사 대응 테이블이라 음수가 섞이면 합계가 조용히 어긋난다.
# 예외도 경고도 안 나므로 검증 하나에 맡기면 알아챌 수단이 없다.
#
# 상한(<= 9_999_999)은 DB 로 내리지 않는다. 물리적 정합성이 아니라
# 「하루 매출이 1000만을 넘으면 입력 실수일 것」이라는 업무 규칙이고, 바뀔 수 있다.
#
# 운영 데이터에 위반 행이 없음을 Supabase 에서 확인했다(두 테이블 다 0건).
# 위반 행이 있으면 ADD CONSTRAINT 가 실패하고 배포 빌드째로 멈춘다.
class AddAmountCheckConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :sales_records,   "amount >= 0", name: "chk_sales_amount"
    add_check_constraint :expense_records, "amount >= 0", name: "chk_expense_amount"
  end
end
