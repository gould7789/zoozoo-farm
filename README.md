# Zoo Zoo Farm

動物園の飼育員がスマートフォンで現場からすぐに動物管理記録を入力できる、**Webアプリケーション**。

<img width="240" alt="main_logo" src="https://github.com/user-attachments/assets/f377e2ed-7177-4f50-a8ca-1617f3ff3d20" />

---

## 目次

- [概要](#概要)
- [技術スタック](#技術スタック)
- [主な機能](#主な機能)
- [ローカルでの起動方法](#ローカルでの起動方法)
- [ディレクトリ構成](#ディレクトリ構成)
- [ERD](#erd)
- [工夫した点](#工夫した点)

---

## 概要

飼育員として働いていた経験から、紙記録の紛失リスク・現場での即時入力の困難さ・行政監査時の書類探索に数日かかる問題を実際に経験しました。これらの課題を解決するため、飼育員がケージの前で携帯を使って操作できる社内ツールを開発しました。

実際に前職の同僚に使ってもらうことを前提として設計しています。

**🔗 サービスURL:** https://zoozoo-farm.onrender.com

> ⚠️ このサービスはアカウント制です。管理者（Admin）からアカウントを発行してもらう必要があります。

<table>
  <tr>
    <td align="center"><b>デスクトップ</b></td>
    <td align="center" colspan="2"><b>モバイル</b></td>
  </tr>
  <tr>
    <td><img width="420" alt="홈 화면_데스크톱" src="https://github.com/user-attachments/assets/0b62cb82-c97b-4a65-b093-dcaafc0c8bcf" /></td>
    <td><img width="200" alt="홈 화면_모바일" src="https://github.com/user-attachments/assets/003bebf2-3f2b-40e3-933d-9a76713ccc02" /></td>
    <td><img width="200" alt="동물 상세 정보_모바일" src="https://github.com/user-attachments/assets/360770e2-ae71-497d-b89c-9dc2558d820b" /></td>
  </tr>
</table>

---

## 技術スタック

![Ruby](https://img.shields.io/badge/Ruby-4.0-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1-CC0000?style=for-the-badge&logo=rubyonrails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-4-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white)
![RSpec](https://img.shields.io/badge/RSpec-257_examples-A32C2C?style=for-the-badge)
![Render](https://img.shields.io/badge/Render-46E3B7?style=for-the-badge&logo=render&logoColor=black)

---

## 主な機能

- 🔐 **ログイン** — 管理者が発行したアカウントでログイン（会員登録機能なし）
- 🏛 **展示館一覧** — 6つの展示館をカードで表示。要注意の動物と最新のお知らせも集約
- 🦜 **展示館詳細** — 館内の動物をカテゴリ別アコーディオンで表示。カテゴリの追加・表示切替はページ遷移なし（カテゴリの操作はAdmin専用）
- 🐾 **動物詳細** — 個体情報（種・性別・CITES等級・入手経緯）と、健康記録・給餌記録の一覧と入力
- 📢 **お知らせ** — 全体および館別の掲示板。自分の投稿のみ編集・削除可能
- 💰 **売上・経費記録** — 自販機・売店別の売上と経費を月別に管理（Admin専用）
- 📊 **管理者ダッシュボード** — 売上・経費・スタッフ管理への導線をまとめたハブ（Admin専用）
- 👥 **スタッフ管理** — アカウントの発行・退職処理。記録を持つアカウントは削除できない
- 📥 **Excel出力** — 動物一覧・健康記録・給餌記録・売上・経費をxlsxで出力（行政監査対応）

---

## ローカルでの起動方法

### 前提条件

- Ruby 4.0.1
- PostgreSQL 17 以上

### セットアップ

```bash
git clone https://github.com/gould7789/zoozoo-farm.git
cd zoozoo-farm

# 依存関係のインストール
bundle install

# 環境変数（初期Adminアカウント）
# コピーした .env の SEED_ADMIN_EMAIL / SEED_ADMIN_PASSWORD を実際の値に書き換えます
# パスワードは8文字以上
cp .env.example .env

# DBの作成とマイグレーション
bin/rails db:prepare

# シードデータの投入（展示館6件 + Adminアカウント）
bin/rails db:seed
```

### 起動

```bash
# Railsサーバーと Tailwind のビルド監視を同時に起動
bin/dev
```

http://localhost:3000 で `.env` に設定したAdminアカウントからログインできます。

### テスト・静的解析

```bash
# RSpec — 257 examples
bundle exec rspec

# コードスタイル（rubocop-rails-omakase）
bin/rubocop

# セキュリティ静的解析
bin/brakeman
bin/bundler-audit
```

これらはpush / Pull Requestのたびに、GitHub Actionsの5つのジョブで自動実行されます。

| ジョブ | 役割 |
| --- | --- |
| `scan_ruby` | Brakeman でコードの脆弱性、bundler-audit でgemの既知の脆弱性を確認 |
| `scan_js` | importmap audit でJavaScript依存の既知の脆弱性を確認 |
| `lint` | RuboCop（rubocop-rails-omakase）でコードスタイルを統一 |
| `test` | RSpec でモデルとリクエストのテストを実行（257 examples） |
| `system-test` | ブラウザ操作のテスト用の枠（現時点ではケースなし） |

---

## ディレクトリ構成

Railsの規約に沿った構成のため、このプロジェクト固有の部分のみ抜粋します。

```
app/
├── controllers/
│   └── concerns/
│       ├── owner_restriction.rb    # 「本人が作成した記録か」の権限チェック
│       ├── animal_scoped.rb        # ネストしたparamsからZone・Animalを解決
│       └── monthly_filterable.rb   # 売上・経費の年月フィルタ（2画面で共有）
├── models/                         # ビジネスロジックはここに集約（Fat Model, Skinny Controller）
└── views/
script/                             # N+1の計測スクリプト（開発環境専用）
spec/
├── models/                         # バリデーション・スコープ
├── requests/                       # 権限チェック中心
└── support/shared_examples/        # 権限マトリクスを共通化
```

`app/services/` は意図的に作っていません。現状はCRUD中心でControllerとModelに収まるためです。
「アクションが50行を超える」「同じロジックが3箇所以上に現れる」「外部API連携が発生する」の
いずれかに達した時点で切り出す方針にしています。

---

## ERD

<img width="2000" height="762" alt="ERD" src="https://github.com/user-attachments/assets/ac81983b-91a7-4f3c-b844-508fddf8f7b8" />

---

## 工夫した点

### 1. なぜモバイルアプリではなくWebにしたか

飼育員の業務は、ケージの前での現場作業と事務所での書類作業が混在します。特定のデバイスに縛られず、ブラウザさえあればどの機器からでも同じ画面に入れることを優先してWebを選びました。インストールもストア審査も不要で、URLを共有するだけで配布が完了する点も現場向きだと判断しました。

その二つの業務は求めるものが違うため、デスクトップとモバイルは同じ画面を縮めるのではなく、別々のUIとして作りました。デスクトップは事務所での書類作業を想定し、サイドバーに売上・経費・スタッフ管理まで常時展開して、一覧はテーブルで表示します。月ごとの数字を並べて比べる作業だからです。モバイルは現場での即時入力を想定し、下部タブバーは親指の届く4つまでに絞り、管理系は「管理」ハブの中へ畳みました。一覧もテーブルではなくカードにして、健康記録や給餌記録を1件ずつ確認・入力しやすい形にしています。

### 2. N+1は推測せず、測ってから直す

`bullet` gemを入れれば検出はできますが、「どれだけ改善したか」までは分かりません。そこで`sql.active_record`のイベントを拾ってクエリ数と実行時間を数えるスクリプトを書き、修正の前後を同じ条件で比べました。

| 対象 | 修正前 | 修正後 |
| --- | --- | --- |
| お知らせ一覧＋作成者（301件） | 302クエリ / 81.5ms | 2クエリ / 1.7ms |
| 動物一覧＋展示館＋最新健康状態（200件） | 401クエリ / 159.2ms | 3クエリ / 13.6ms |

`includes`を足すだけでは足りないところもありました。読み込み済みの関連に`.recent.first`を呼ぶとまたクエリが飛んでしまうので、読み込み済みかどうかで処理を分けています。

売上・経費の一覧には、N+1とは別の無駄がありました。クエリは1回で済んでいたのですが、画面に出すのは1ヶ月分なのに全件をActiveRecordオブジェクトにしていたのです。月の絞り込みをSQL側に移して、インデックスが効くようにしました。「クエリを何回投げるか」と「1回でどれだけ持ってくるか」は別の話だと整理できた作業でした。

### 3. 監査に備えて記録する

このシステムを作った動機は行政監査への対応でした。なので「記録が後から正しく読めること」を一番の前提にしています。

現場では昨日観察した内容を今日入力することが必ずあるため、観察日と入力日時は別のカラムに分けました。退職者のアカウントも消さずに在職フラグで残して、過去の記録から作成者が消えないようにしています。記録を1件でも持つユーザーはそもそも削除できないようにして、退職処理のほうへ促しています。

### 4. 認証をDeviseに頼らず実装した

Adminがアカウントを発行して渡す運用なので会員登録画面が要らず、Deviseの機能の大半は使い道がありませんでした。`has_secure_password`とSessionsControllerで組んでいます。

- ログイン時にセッションIDを再発行してセッション固定攻撃を防ぎ、ログアウトでも同じことをしています
- 現在のユーザーを在職者に絞って引いているので、退職処理をした瞬間にログイン中でも締め出されます
- 権限は「役割（正社員のAdmin / アルバイトのStaff）」と「本人が書いた記録か」の2軸で見ています
- ログイン試行の制限はIPではなくメールアドレス単位にしました。現場では同じWi-Fiに複数人がつながるので、IP基準だと一人の入力ミスで全員が締め出されてしまうからです

### 5. 主キーにUUID v4を選んだ理由

連番IDはURLの数字を変えるだけで他人のデータに辿り着けてしまうので、IDOR対策としてUUIDにしました。

v7ではなくv4です。v7の利点は時刻順に並んでインデックスがまとまることですが、このアプリは観察日・給餌日時・売上日といった日付カラムを別に持っていて、一覧の並び替えはすべてそちらでやります。主キーで時系列に並べる場面がないので、その利点が効きません。むしろv7は生成時刻がURLに出てしまうため、IDOR対策としてはランダムなv4のほうが都合が良いと考えました。
