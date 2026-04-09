# シードデータ — 何度実行しても同じ結果になるようにfind_or_create_by!を使用

# ① 展示館6件（固定データ — Admin UIなし）
zone_names = [ "사랑새관", "앵무새관", "파충류관", "미니동물관", "야외동물체험관", "격리실" ]
zone_names.each do |name|
  Zone.find_or_create_by!(name: name)
end
puts "✓ Zones seeded: #{Zone.count}件"

# ② Admin初期アカウント（認証情報は .env から読み込む）
admin_email    = ENV.fetch("SEED_ADMIN_EMAIL")    { raise "SEED_ADMIN_EMAIL is not set" }
admin_password = ENV.fetch("SEED_ADMIN_PASSWORD") { raise "SEED_ADMIN_PASSWORD is not set" }

User.find_or_create_by!(email: admin_email) do |u|
  u.name     = "Admin"
  u.password = admin_password
  u.role     = :admin
end
puts "✓ Admin user seeded (#{admin_email})"
