# セッションの有効期限。
#
# 既定では expire_after が無く、ブラウザを閉じるまでクッキーが生き続ける。
# 現場のスマホはブラウザをほとんど閉じないので、実質無期限だった。
#
# 9時間にしているのは1日の勤務時間に合わせたため。出勤時に一度ログインすれば
# 退勤まで切れず、翌朝は入り直す。事務所の共有PCに置きっぱなしでも夜には切れる。
#
# CookieStore は毎レスポンスでクッキーを書き直すので、これは「最終操作からの
# 9時間」であって「ログインからの9時間」ではない。作業中に切れることはない。
#
# なお退職処理（active = false）はこの期限とは独立に即座に効く。
# current_user が毎リクエスト User.active を引き直すため、
# クッキーが生きていてもログイン画面へ戻される。
Rails.application.config.session_store :cookie_store,
  key: "_zoo_keeper_session",
  expire_after: 9.hours
