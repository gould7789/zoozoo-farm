# 시드 — 몇 번 실행해도 같은 결과가 되도록 find_or_create_by! 를 쓴다

# ① 관 6개 (고정 데이터 — Admin UI 없음)
zone_names = [ "사랑새관", "앵무새관", "파충류관", "미니동물관", "야외동물체험관", "격리실" ]
zone_names.each do |name|
  Zone.find_or_create_by!(name: name)
end
puts "Zones seeded: #{Zone.count}개"

# ② Admin 초기 계정 (인증 정보는 .env 에서 읽는다)
admin_email    = ENV.fetch("SEED_ADMIN_EMAIL")    { raise "SEED_ADMIN_EMAIL is not set" }
admin_password = ENV.fetch("SEED_ADMIN_PASSWORD") { raise "SEED_ADMIN_PASSWORD is not set" }

User.find_or_create_by!(email: admin_email) do |u|
  u.name     = "Admin"
  u.password = admin_password
  u.role     = :admin
end
puts "Admin user seeded (#{admin_email})"
