# Zoo Zoo Farm

動物園の飼育員がスマートフォンで現場からすぐに動物管理記録を入力できる、**モバイルファーストのWebアプリケーション**。

---

## 目次

- [概要](#概要)
- [技術スタック](#技術スタック)
- [主な機能](#主な機能)
- [ERD](#erd)

---

## 概要

動物園で4年間飼育員として働いていた経験から、紙記録の紛失リスク・現場での即時入力の困難さ・行政監査時の書類探索に数日かかる問題を実際に経験しました。これらの課題を解決するため、飼育員がケージの前でスマートフォンを片手に操作できる社内ツールを開発しました。

実際に前職の同僚に使ってもらうことを前提として設計しています。

**🔗 サービスURL:** https://zoozoo-farm.onrender.com

> ⚠️ このサービスはアカウント制です。管理者（Admin）からアカウントを発行してもらう必要があります。

---

## 技術スタック

![Ruby on Rails](https://img.shields.io/badge/Ruby_on_Rails-CC0000?style=for-the-badge&logo=ruby-on-rails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white)
![Render](https://img.shields.io/badge/Render-46E3B7?style=for-the-badge&logo=render&logoColor=white)
![RSpec](https://img.shields.io/badge/RSpec-CC0000?style=for-the-badge&logo=ruby&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)

---

## 主な機能

### 1. ログイン画面 `/login`

管理者から発行されたアカウントでログインする画面。会員登録機能はなく、Adminがアカウントを作成してStaffに渡す運用。

<table>
  <tr>
    <td align="center"><b>デスクトップ</b></td>
    <td align="center"><b>モバイル</b></td>
  </tr>
  <tr>
    <td><img src="" width="500"/></td>
    <td><img src="" width="250"/></td>
  </tr>
</table>

---

### 2. 展示館一覧（ホーム） `/`

動物園内の6つの展示館をカードで表示する。ログイン後の最初の画面。

<table>
  <tr>
    <td align="center"><b>デスクトップ</b></td>
    <td align="center"><b>モバイル</b></td>
  </tr>
  <tr>
    <td><img src="" width="500"/></td>
    <td><img src="" width="250"/></td>
  </tr>
</table>

---

### 3. 展示館詳細 `/zones/:id`

館内の動物をカテゴリ別アコーディオンで表示。AdminはカテゴリをTurbo Streamsでページ遷移なしに追加・表示切り替えが可能。

<table>
  <tr>
    <td align="center"><b>デスクトップ</b></td>
    <td align="center"><b>モバイル</b></td>
  </tr>
  <tr>
    <td><img src="" width="500"/></td>
    <td><img src="" width="250"/></td>
  </tr>
</table>

---

### 4. 動物詳細 `/zones/:id/animals/:id`

個体情報（種・性別・CITES等級・入手経緯など）の確認と、健康記録・給餌記録の一覧・追加・編集。Staffは自分が入力した記録のみ編集・削除可能。

<table>
  <tr>
    <td align="center"><b>デスクトップ</b></td>
    <td align="center"><b>モバイル</b></td>
  </tr>
  <tr>
    <td><img src="" width="500"/></td>
    <td><img src="" width="250"/></td>
  </tr>
</table>

---

### 5. お知らせ `/notices`

全体および館別カテゴリのお知らせ掲示板。Admin・Staff両方が投稿でき、自分の投稿のみ編集・削除可能。

<table>
  <tr>
    <td align="center"><b>デスクトップ</b></td>
    <td align="center"><b>モバイル</b></td>
  </tr>
  <tr>
    <td><img src="" width="500"/></td>
    <td><img src="" width="250"/></td>
  </tr>
</table>

---

### 6. 売上・経費記録 `/sales` `/expenses`

自販機・売店別の売上入力と、動物購入費・医療費などの経費入力。月別フィルタリングに対応。Admin専用。

<table>
  <tr>
    <td align="center"><b>デスクトップ</b></td>
    <td align="center"><b>モバイル</b></td>
  </tr>
  <tr>
    <td><img src="" width="500"/></td>
    <td><img src="" width="250"/></td>
  </tr>
</table>

---

### 7. 管理者ダッシュボード `/admin/dashboard`

売上・経費・スタッフ管理への導線をまとめた管理hub画面。Admin専用。

<table>
  <tr>
    <td align="center"><b>デスクトップ</b></td>
    <td align="center"><b>モバイル</b></td>
  </tr>
  <tr>
    <td><img src="" width="500"/></td>
    <td><img src="" width="250"/></td>
  </tr>
</table>

---

### 8. スタッフ管理 `/admin/members`

Staffアカウントの作成・編集・退職処理（論理削除）。退職後もデータは保持され監査対応に活用できる。Admin専用。

<table>
  <tr>
    <td align="center"><b>デスクトップ</b></td>
    <td align="center"><b>モバイル</b></td>
  </tr>
  <tr>
    <td><img src="" width="500"/></td>
    <td><img src="" width="250"/></td>
  </tr>
</table>

---

## ERD

<img width="2000" height="762" alt="ERD" src="https://github.com/user-attachments/assets/ac81983b-91a7-4f3c-b844-508fddf8f7b8" />
