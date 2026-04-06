# 🦁 Zoo Keeper

動物園の飼育員がスマートフォンで現場からすぐに動物管理記録を入力できる、**モバイルファーストのWebアプリケーション**。

---

## プロジェクト概要

動物園の現場で飼育員がケージの前でスマートフォンを操作するシナリオを想定して設計しました。

- 動物個体ごとの健康記録・給餌記録の管理
- ロールベースのアクセス制御（Admin / Staff）
- 展示館単位での動物分類およびお知らせ機能
- Admin専用の売上・経費記録管理

---

## 技術スタック

| 項目 | 内容 |
|------|------|
| Language | Ruby 4.0.1 |
| Framework | Ruby on Rails 8.1 |
| Database | PostgreSQL |
| CSS | Tailwind CSS（モバイルファースト） |
| Frontend | Hotwire（Turbo + Stimulus） |
| 認証 | has_secure_password（bcrypt） |
| テスト | RSpec / FactoryBot / Shoulda-Matchers / Capybara |
| CI/CD | GitHub Actions → Render 自動デプロイ |
| セキュリティ | Brakeman / bundler-audit |
| Linter | RuboCop（rails-omakase） |

---

## 主な機能

### Admin（正社員飼育員）
- 全動物のCRUD操作
- すべての健康・給餌記録の編集・削除
- Staffアカウントの作成・退職処理（論理削除）
- 売上・経費記録の管理
- 全体・館別お知らせの作成

### Staff（アルバイト飼育員）
- 健康記録の追加（自分の記録のみ編集・削除）
- 給餌記録の追加（自分の記録のみ編集・削除）
- お知らせの確認

---

## ER図

<!-- ER図画像を挿入予定 -->
> `docs/erd.png` 追加予定

```
zones（シードデータで固定）
  └── animals
        ├── health_records  (created_by → users)
        └── feeding_records (created_by → users)

users
  ├── health_records
  ├── feeding_records
  ├── notices
  ├── sales_records
  └── expense_records
```

---

## フォルダ構成

```
zoo-keeper/
├── .github/workflows/ci.yml           # RuboCop + Brakeman + RSpec 自動実行
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb  # 認証ヘルパー（require_login / require_admin）
│   │   ├── sessions_controller.rb
│   │   ├── zones_controller.rb
│   │   ├── animals_controller.rb
│   │   ├── health_records_controller.rb
│   │   ├── feeding_records_controller.rb
│   │   ├── notices_controller.rb
│   │   ├── sales_records_controller.rb
│   │   ├── expense_records_controller.rb
│   │   └── admin/users_controller.rb
│   ├── models/
│   │   ├── user.rb             # has_secure_password, enum role
│   │   ├── zone.rb
│   │   ├── animal.rb           # enum gender, cites_grade
│   │   ├── health_record.rb    # enum condition
│   │   ├── feeding_record.rb
│   │   ├── notice.rb           # enum category
│   │   ├── sales_record.rb     # enum source
│   │   └── expense_record.rb   # enum category
│   └── views/
│       ├── layouts/application.html.erb  # 下部タブバー
│       ├── sessions/
│       ├── zones/
│       ├── animals/
│       ├── health_records/
│       ├── feeding_records/
│       ├── notices/
│       ├── sales_records/
│       ├── expense_records/
│       └── admin/users/
├── db/
│   ├── migrate/                # マイグレーション（8テーブル）
│   └── seeds.rb                # 展示館6件 + Admin初期アカウント
├── spec/
│   ├── models/                 # モデル単体テスト
│   ├── requests/               # 権限テスト
│   ├── system/                 # Capybara E2Eテスト
│   ├── factories/              # FactoryBot
│   └── support/
└── config/routes.rb
```

---

## ローカル実行手順

```bash
# 1. 依存関係のインストール
bundle install

# 2. データベースの作成・マイグレーション
rails db:create
rails db:migrate

# 3. シードデータの投入（展示館6件 + Adminアカウント）
rails db:seed

# 4. 開発サーバーの起動
rails server
# → http://localhost:3000

# 初期ログイン情報
# Email:    admin@zoo.local
# Password: changeme
```

---

## テスト実行

```bash
# 全テスト
bundle exec rspec

# モデルテストのみ
bundle exec rspec spec/models

# 権限（Request）テストのみ
bundle exec rspec spec/requests

# E2Eテストのみ
bundle exec rspec spec/system

# コードスタイル検査
bundle exec rubocop

# セキュリティ脆弱性検査
bundle exec brakeman
```

---

## 設計上の判断とその根拠

| 判断 | 理由 |
|------|------|
| Devise不使用 | 学習目的でSession / Cookie / bcryptを直接実装 |
| scaffold不使用 | MVCの流れを手で書いて習得するため |
| 論理削除（`active = false`） | 退職ユーザー・死亡動物の記録を監査証跡として保持 |
| `recorded_on`を分離 | 現場での観察日とシステム入力日が異なるケースに対応 |
| zonesをシード固定 | 新館は数年に一度 → Admin UIは不要、誤削除防止 |
| `amount`をinteger型 | 円単位は小数点なし → decimalより安全かつ高速 |
| `created_by`カラム | Staff自身の記録のみ編集・削除できる権限チェック + 監査追跡 |
| Fat Model / Skinny Controller | ビジネスロジックはModelに集約 |
| Renderでデプロイ | Nginx / Docker不要でSSL・ドメインを自動処理 |

---

## ブランチ戦略

```
main              ← デプロイ可能な安定バージョン
  └── develop
        ├── setup/init
        ├── feature/auth
        ├── feature/animals
        ├── feature/health
        ├── feature/feeding
        ├── feature/notices
        ├── feature/sales
        ├── feature/expenses
        └── feature/admin
```
