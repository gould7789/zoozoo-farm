# シードデータ — 何度実行しても同じ結果になるようにfind_or_create_by!を使用

# ① 展示館6件（固定データ — Admin UIなし）
zone_names = [ "사랑새관", "앵무새관", "파충류관", "미니동물관", "야외동물체험관", "격리실" ]
zone_names.each do |name|
  Zone.find_or_create_by!(name: name)
end
puts "✓ Zones seeded: #{Zone.count}件"

# ② Admin初期アカウント
User.find_or_create_by!(email: "admin@zoo.local") do |u|
  u.name     = "Admin"
  u.password = "changeme"
  u.role     = :admin
end
puts "✓ Admin user seeded"
puts ""
puts "初期ログイン情報:"
puts "  Email:    admin@zoo.local"
puts "  Password: changeme"
