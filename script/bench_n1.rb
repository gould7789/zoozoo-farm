# frozen_string_literal: true

# ─────────────────────────────────────────────────────────────
# N+1 정량 측정 (★개발 환경 전용 / 데이터 변경 없음★)
# 実行: bin/rails runner script/bench_n1.rb
# 먼저 script/seed_bench.rb 로 더미 데이터를 넣어두면 유의미한 수치가 나온다.
#
# 시나리오 A: 공지 목록에서 작성자(created_by) 표시  ← 실제 수정 대상(커밋 532ce30)
# 시나리오 B: 동물 목록 + 소속 관 + 최신 건강상태   ← zones#show 계열
# 각각 ① includes 없음(N+1)  vs  ② includes 적용  비교.
# ─────────────────────────────────────────────────────────────
RUNS = 5

def count_queries
  n = 0
  sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |*a|
    name = a.last[:name].to_s
    n += 1 unless name =~ /SCHEMA|TRANSACTION/i
  end
  yield
  n
ensure
  ActiveSupport::Notifications.unsubscribe(sub)
end

def best_ms(runs)
  times = (1..runs).map do
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
  end
  (times.min * 1000).round(1)
end

def report(title, scope_count, naive, optimized)
  q1 = count_queries { naive.call };     t1 = best_ms(RUNS) { naive.call }
  q2 = count_queries { optimized.call }; t2 = best_ms(RUNS) { optimized.call }
  puts "■ #{title}  (대상 #{scope_count}건)"
  puts "   ① N+1 (includes 없음) : 쿼리 #{q1}개,  #{t1} ms"
  puts "   ② 해결 (includes)     : 쿼리 #{q2}개,  #{t2} ms"
  puts "   → 쿼리 #{q1} → #{q2}개,  시간 #{t1} → #{t2} ms" \
       "#{t2 > 0 ? " (#{(t1 / t2).round(1)}배)" : ''}"
  puts ""
end

puts "─" * 60
# ── 시나리오 A: 공지 목록 + 작성자 ──
notice_n = Notice.count
report("공지 목록 — 작성자 표시", notice_n,
  -> { Notice.recent.to_a.each { |x| x.created_by&.name } },
  -> { Notice.recent.includes(:created_by).to_a.each { |x| x.created_by&.name } })

# ── 시나리오 B: 동물 목록 + 관 + 최신 건강상태 ──
LIMIT = (ENV["LIMIT"] || 200).to_i
animal_n = Animal.active.limit(LIMIT).count
report("동물 목록 — 관 이름 + 최신 건강상태", animal_n,
  -> { Animal.active.limit(LIMIT).to_a.each { |a| a.zone.name; a.health_records.order(recorded_on: :desc, id: :desc).first&.condition } },
  -> { Animal.active.includes(:zone, :health_records).limit(LIMIT).to_a.each { |a| a.zone.name; a.health_records.max_by { |h| [ h.recorded_on, h.id ] }&.condition } })
puts "─" * 60
puts "※ 이 출력을 그대로 붙여주시면 슬라이드에 실측값을 넣어드립니다."
