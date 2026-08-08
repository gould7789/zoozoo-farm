# frozen_string_literal: true

# ─────────────────────────────────────────────────────────────
# 벤치용 더미 데이터 전체 삭제 (★개발 환경 전용★)
# 実行: bin/rails runner script/cleanup_bench.rb
# ─────────────────────────────────────────────────────────────
abort("⚠ 개발 환경에서만 실행하세요 (현재: #{Rails.env})") unless Rails.env.development?

# Demo 동물 삭제 → health/feeding은 dependent: :destroy 로 함께 삭제
animals = Animal.where("species LIKE 'Demo종%'")
a_cnt = animals.count
animals.destroy_all

notices = Notice.where("body LIKE '벤치 공지%'")
n_cnt = notices.count
notices.destroy_all

users = User.where(email: [ "bench_admin@example.com", "bench_staff@example.com" ])
u_cnt = users.count
users.destroy_all

puts "🧹 정리 완료 — 동물 #{a_cnt} / 공지 #{n_cnt} / 사용자 #{u_cnt} 삭제"
