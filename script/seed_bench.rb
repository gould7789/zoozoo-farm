# frozen_string_literal: true

# ─────────────────────────────────────────────────────────────
# N+1 측정용 더미 데이터 시드 (★개발 환경 전용★)
# 実行: bin/rails runner script/seed_bench.rb
#   옵션: ANIMALS=40 RECORDS=8 NOTICES=300 bin/rails runner script/seed_bench.rb
# 측정이 끝나면 script/cleanup_bench.rb 로 전부 삭제할 수 있다.
# ─────────────────────────────────────────────────────────────
abort("⚠ 개발 환경에서만 실행하세요 (현재: #{Rails.env})") unless Rails.env.development?

ANIMALS_PER_ZONE = (ENV["ANIMALS"] || 40).to_i
RECORDS_PER      = (ENV["RECORDS"] || 8).to_i
NOTICES          = (ENV["NOTICES"] || 300).to_i

admin = User.find_or_create_by!(email: "bench_admin@example.com") do |u|
  u.name = "벤치관리자"; u.password = "password123"; u.role = :admin
  u.position = :manager; u.active = true
end
staff = User.find_or_create_by!(email: "bench_staff@example.com") do |u|
  u.name = "벤치직원"; u.password = "password123"; u.role = :staff; u.active = true
end
users = [ admin, staff ]

zones = Zone.all.to_a
abort("Zone 시드가 먼저 필요합니다 (bin/rails db:seed)") if zones.empty?

animals = 0
zones.each do |z|
  ANIMALS_PER_ZONE.times do |i|
    a = z.animals.create!(
      species: "Demo종#{i}", name: "벤치개체#{i}",
      individual_count: 1, active: true,
      gender: %i[male female unknown].sample
    )
    RECORDS_PER.times do |j|
      a.health_records.create!(created_by: users.sample, recorded_on: Date.today - j,
                               condition: %i[normal caution danger].sample,
                               weight_kg: rand(1.0..30.0).round(2))
      a.feeding_records.create!(created_by: users.sample, fed_at: Time.current - j.days,
                                food_type: %w[펠렛 채소 과일 곤충].sample, amount_g: rand(10..500))
    end
    animals += 1
  end
end

NOTICES.times do |i|
  Notice.create!(created_by: users.sample, category: Notice.categories.keys.sample,
                 body: "벤치 공지 #{i} — 측정용 더미 데이터")
end

puts "✅ 시드 완료 — 동물 #{animals}마리 / 공지 #{NOTICES}건 (작성자 표시 화면 측정용)"
puts "   다음: bin/rails runner script/bench_n1.rb"
