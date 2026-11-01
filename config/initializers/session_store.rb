# 세션 유효 기간 — 9시간은 하루 근무 시간에 맞춘 것이다.
# 왜 기본값으로 두지 않는지와 「마지막 조작으로부터」인 이유는
# .claude/rules/notes/auth.md
Rails.application.config.session_store :cookie_store,
  key: "_zoo_keeper_session",
  expire_after: 9.hours
