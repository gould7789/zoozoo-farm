# Zoo Zoo Farm

動物園の飼育員がスマートフォンで現場からすぐに動物管理記録を入力できる、**モバイルファーストのWebアプリケーション**。

---

## プロジェクト概要

動物園の現場で飼育員がケージの前でスマートフォンを操作するシナリオを想定して設計しました。

- 動物個体ごとの健康記録・給餌記録の管理
- ロールベースのアクセス制御（Admin / Staff）
- 展示館単位での動物分類およびお知らせ機能
- Admin専用の売上・経費記録管理
- 管理者ダッシュボード・マイページ機能

---

## 技術スタック

| 項目         | 内容                                       |
| ------------ | ------------------------------------------ |
| Language     | Ruby                                       |
| Framework    | Ruby on Rails                              |
| Frontend     | HTML(ERB) / CSS(Tailwind CSS) / JavaScript |
| Database     | PostgreSQL（UUID v7 主キー）               |
| 認証         | has_secure_password（bcrypt）              |
| テスト       | RSpec / FactoryBot / Shoulda-Matchers      |
| CI/CD        | GitHub Actions → Render 自動デプロイ       |
| セキュリティ | Brakeman / bundler-audit                   |
| Linter       | RuboCop                                    |

---

## 主な機能

### Admin（正社員飼育員）

- 全動物のCRUD操作
- すべての健康・給餌記録の編集・削除
- Staffアカウントの作成・退職処理（論理削除）
- 売上・経費記録の管理（月別フィルター）
- 全体・館別お知らせの作成・編集・削除
- 管理者ダッシュボード（売上・経費・職員管理ハブ）

### Staff（アルバイト飼育員）

- 健康記録の追加（自分の記録のみ編集・削除）
- 給餌記録の追加（自分の記録のみ編集・削除）
- お知らせの確認・作成（自分の投稿のみ編集・削除）
- マイページで自身のアカウント情報を確認

---

## ER図

<img width="2790" height="762" alt="データベースERD" src="https://github.com/user-attachments/assets/17e31f2e-30af-4380-84f6-83f2ce6ee1c6" />

---

## データベース設計

### 主キー

全テーブルで **UUID v7** を採用。時系列ソートが可能で、連番IDによる推測攻撃を防止。

### Userモデルの追加フィールド

初期設計から以下のフィールドを追加し、実際の運用に対応：

| フィールド         | 型      | 用途                                  |
| ------------------ | ------- | ------------------------------------- |
| `position`         | enum    | 職位（junior〜general_manager 6段階） |
| `is_team_leader`   | boolean | チームリーダー表示フラグ              |
| `hired_on`         | date    | 入社日                                |
| `contract_ends_on` | date    | 契約終了日（Staffのみ）               |

### ルーティング（内部テーブル名の隠蔽）

| URL                                  | コントローラー    | 理由                     |
| ------------------------------------ | ----------------- | ------------------------ |
| `/zones/:id/animals/:id/health_logs` | `health_records`  | 内部DB名の隠蔽           |
| `/sales`                             | `sales_records`   | URLを簡潔に              |
| `/expenses`                          | `expense_records` | URLを簡潔に              |
| `/admin/members`                     | `admin/users`     | ユーザー向けに自然な名称 |

---

## フォルダ構成

```
zoozoo-farm/
├── .github/workflows/
│   └── ci.yml                         # RuboCop + Brakeman + RSpec 自動実行（5 Job）
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb  # 認証ヘルパー（require_login / require_admin）
│   │   ├── sessions_controller.rb     # ログイン・ログアウト（セッション固定攻撃対策）
│   │   ├── zones_controller.rb
│   │   ├── animals_controller.rb
│   │   ├── health_records_controller.rb
│   │   ├── feeding_records_controller.rb
│   │   ├── notices_controller.rb
│   │   ├── sales_records_controller.rb
│   │   ├── expense_records_controller.rb
│   │   ├── accounts_controller.rb     # マイページ
│   │   └── admin/
│   │       ├── users_controller.rb    # 職員管理（Admin専用）
│   │       └── dashboard_controller.rb # 管理者メニューハブ
│   ├── models/
│   │   ├── user.rb                    # has_secure_password, enum role / position
│   │   ├── zone.rb
│   │   ├── animal.rb                  # enum gender, cites_grade
│   │   ├── health_record.rb           # enum condition
│   │   ├── feeding_record.rb
│   │   ├── notice.rb                  # enum category（7種類）
│   │   ├── sales_record.rb            # enum source（自販機4台 + 売店）
│   │   └── expense_record.rb          # enum category（6種類）
│   └── views/
│       ├── layouts/
│       │   ├── application.html.erb   # 共通レイアウト
│       │   ├── _sidebar.html.erb      # デスクトップ用サイドナビ
│       │   ├── _bottom_nav.html.erb   # モバイル用タブバー
│       │   └── _flash.html.erb        # フラッシュメッセージ
│       ├── sessions/                  # ログイン画面
│       ├── zones/                     # 館一覧・詳細
│       ├── animals/                   # 動物CRUD
│       ├── health_records/            # 健康記録CRUD
│       ├── feeding_records/           # 給餌記録CRUD
│       ├── notices/                   # お知らせCRUD
│       ├── sales_records/             # 売上記録（月別フィルター）
│       ├── expense_records/           # 経費記録（月別フィルター）
│       ├── accounts/                  # マイページ
│       └── admin/
│           ├── users/                 # 職員管理
│           └── dashboard/             # 管理者メニュー
├── db/
│   ├── migrate/                       # マイグレーション（8テーブル + UUID v7）
│   └── seeds.rb                       # 展示館6件 + Admin初期アカウント（環境変数）
├── spec/
│   ├── models/                        # モデル単体テスト（8ファイル）
│   ├── requests/                      # 権限テスト（11ファイル）
│   ├── factories/                     # FactoryBot（8ファイル）
│   ├── support/                       # Shoulda-Matchers / RequestHelpers
│   └── system/                        # E2Eテスト（未実装）
└── config/routes.rb
```

---

## ローカル実行手順

```bash
# 1. 依存関係のインストール
bundle install

# 2. 環境変数の設定（.envまたはシェル）
export SEED_ADMIN_EMAIL=admin@zoo.local
export SEED_ADMIN_PASSWORD=changeme

# 3. データベースの作成・マイグレーション
rails db:create
rails db:migrate

# 4. シードデータの投入（展示館6件 + Adminアカウント）
rails db:seed

# 5. 開発サーバーの起動
rails server
# → http://localhost:3000

# 初期ログイン情報
# Email:    $SEED_ADMIN_EMAIL の値
# Password: $SEED_ADMIN_PASSWORD の値
```

---

## テスト実行

```bash
# 全テスト
bundle exec rspec spec

# モデルテストのみ
bundle exec rspec spec/models

# 権限（Request）テストのみ
bundle exec rspec spec/requests

# コードスタイル検査
bundle exec rubocop

# セキュリティ脆弱性検査
bundle exec brakeman --no-pager
```

---

## ブランチ

```
main                    ← デプロイ可能な安定バージョン
  └── develop
        ├── setup/init          # RSpec・FactoryBot・CI初期設定
        ├── feature/auth        # ログイン・ログアウト・セッション管理
        ├── feature/animals     # 館・動物 CRUD
        ├── feature/health      # 健康記録 CRUD
        ├── feature/feeding     # 給餌記録 CRUD
        ├── feature/notices     # お知らせ CRUD
        ├── feature/sales       # 売上記録 CRUD（Admin専用）
        ├── feature/expenses    # 経費記録 CRUD（Admin専用）
        ├── feature/admin       # 職員管理・管理者ダッシュボード
        ├── feature/my-page     # マイページ・下部タブバー再設計
        ├── style/mobile        # Tailwindモバイルファーストレイアウト
        └── deploy/production   # UUID v7・韓国ロケール・セッション固定対策
```
