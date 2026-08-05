# config.time_zone未設定（UTC動作）の期間に登録されたfed_atを補正する
#
# 経緯: 入力フォームはdate_default_controller.jsがブラウザのローカル時刻（KST）で
# 埋めるが、Railsがその文字列をUTCとして解釈して保存していた。
# そのため「08:00 KSTの給餌」が「08:00 UTC（= 17:00 KST）」として記録されている。
#
# 画面上は入力値と表示値が一致するため気づきにくいが、DBの値自体が9時間ずれている。
# 実測ではfed_atとcreated_atの差が約+9時間になっており、これが根拠となる。
#
# created_at / updated_atはRailsが生成した正確なUTC時刻のため補正しない。
# recorded_on / sold_on / spent_onはDATE型でタイムゾーン変換の対象外。
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
