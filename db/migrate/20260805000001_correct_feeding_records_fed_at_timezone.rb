# config.time_zone 을 안 잡아둔(UTC 로 동작) 기간에 들어온 fed_at 을 바로잡는다
#
# 경위: 입력 폼은 date_default_controller.js 가 브라우저 로컬 시각(KST)으로 채우는데,
# Rails 가 그 문자열을 UTC 로 해석해 저장했다.
# 그래서 「08:00 KST 의 급여」가 「08:00 UTC(= 17:00 KST)」로 기록돼 있다.
#
# 화면에서는 입력값과 표시값이 맞아 알아채기 어렵지만 DB 의 값 자체가 9시간 어긋나 있다.
# 실측으로 fed_at 과 created_at 의 차가 약 +9시간이었고, 그게 근거다.
#
# created_at / updated_at 은 Rails 가 만든 정확한 UTC 라 건드리지 않는다.
# recorded_on / sold_on / spent_on 은 DATE 형이라 타임존 변환 대상이 아니다.
class CorrectFeedingRecordsFedAtTimezone < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE feeding_records
      SET fed_at = fed_at - INTERVAL '9 hours'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE feeding_records
      SET fed_at = fed_at + INTERVAL '9 hours'
    SQL
  end
end
