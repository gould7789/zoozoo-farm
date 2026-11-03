# 테이블이 무엇을 담는지 DB 에 심는다.
# schema.rb 는 자동 생성이라 손으로 적으면 db:migrate 때 날아간다 —
# COMMENT ON TABLE 로 심으면 덤프가 create_table ..., comment: 로 되살린다
class AddTableComments < ActiveRecord::Migration[8.1]
  COMMENTS = {
    zones:             "동물을 두는 구역. 시드 고정이라 화면에서 만들지 않는다",
    animal_categories: "관 안에서 동물을 종류별로 묶는 분류. 숨김 토글이 있다",
    animals:           "동물 개체. 이름이 없는 종은 individual_count 에 마리 수를 넣는다",
    health_records:    "개체의 컨디션과 체중 관찰 기록",
    feeding_records:   "개체의 먹이 급여 이력",
    notices:           "직원 공지. 본문은 Action Text 리치텍스트다",
    sales_records:     "매출 기록. Admin 전용",
    expense_records:   "지출 기록. Admin 전용",
    users:             "직원 계정. 회원가입이 없고 Admin 이 발급한다. 퇴사는 active = false"
  }.freeze

  def up
    COMMENTS.each { |table, text| change_table_comment table, from: nil, to: text }
  end

  def down
    COMMENTS.each { |table, text| change_table_comment table, from: text, to: nil }
  end
end
