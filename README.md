# Zoo Zoo Farm

動物園の飼育員がスマートフォンで現場からすぐに動物管理記録を入力できる、**Webアプリケーション**。
<img width="600" height="800" alt="main_logo" src="https://github.com/user-attachments/assets/f377e2ed-7177-4f50-a8ca-1617f3ff3d20" />

---

## 目次

- [概要](#概要)
- [技術スタック](#技術スタック)
- [主な機能](#主な機能)
- [ERD](#erd)

---

## 概要

飼育員として働いていた経験から、紙記録の紛失リスク・現場での即時入力の困難さ・行政監査時の書類探索に数日かかる問題を実際に経験しました。これらの課題を解決するため、飼育員がケージの前でスマートフォンを片手に操作できる社内ツールを開発しました。

実際に前職の同僚に使ってもらうことを前提として設計しています。

**🔗 サービスURL:** https://zoozoo-farm.onrender.com

> ⚠️ このサービスはアカウント制です。管理者（Admin）からアカウントを発行してもらう必要があります。

---

## 技術スタック

![Ruby on Rails](https://img.shields.io/badge/Ruby_on_Rails-CC0000?style=for-the-badge&logo=ruby-on-rails&logoColor=white)

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
    <td><img width="500" alt="로그인_데스크톱" src="https://github.com/user-attachments/assets/ae9c1e06-598d-428e-9d7b-de76b18db8d5"/></td>
    <td><img width="250" alt="로그인_모바일" src="https://github.com/user-attachments/assets/8164094a-1d97-4b9d-8b02-aa14ac1696e7" />
</td>
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
    <td><img width="500" alt="홈 화면_데스크톱" src="https://github.com/user-attachments/assets/0b62cb82-c97b-4a65-b093-dcaafc0c8bcf" /></td>
    <td><img width="250" alt="홈 화면_모바일" src="https://github.com/user-attachments/assets/003bebf2-3f2b-40e3-933d-9a76713ccc02" /></td>
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
    <td><img width="500" alt="관 상세 화면_데스크톱" src="https://github.com/user-attachments/assets/72b6d470-a5fb-454b-bb74-bd553bd12838" /></td>
    <td><img width="250"alt="관 상세 화면_모바일" src="https://github.com/user-attachments/assets/dd1b4a1c-5f42-4148-96d4-0ae63551f572" /></td>
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
    <td><img width="500" alt="동물 상세 정보_데스크톱" src="https://github.com/user-attachments/assets/b5a325eb-06d7-433e-823a-1b646b49e9e1" /></td>
    <td><img width="250" alt="동물 상세 정보_모바일" src="https://github.com/user-attachments/assets/360770e2-ae71-497d-b89c-9dc2558d820b" /></td>
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
    <td><img width="500" alt="공지_데스크톱" src="https://github.com/user-attachments/assets/5a0641c4-19e0-4a29-8b76-9538fb69fdf8" /></td>
    <td><img width="250" alt="공지_모바일" src="https://github.com/user-attachments/assets/f6e6593f-f767-4d26-a078-2fe18c523ab3" /></td>
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
    <td><img width="500" alt="매출_데스크톱" src="https://github.com/user-attachments/assets/4fd64bef-1f5a-4c61-a00e-618ba1e32429" /></td>
    <td><img width="250" alt="지출_모바일" src="https://github.com/user-attachments/assets/48387c31-4a56-4b3c-8aaf-bd464c3bdb1a" /></td>
  </tr>
</table>

---

### 7. 管理者ダッシュボード `/admin/dashboard`

売上・経費・スタッフ管理への導線をまとめた管理hub画面。モバイルのAdmin専用。

<table>
  <tr>
    <td align="center"><b>モバイル</b></td>
  </tr>
  <tr>
    <td><img width="250" alt="관리 허브 페이지_모바일" src="https://github.com/user-attachments/assets/790f843a-670f-4d78-b14e-1e9b57a8b028" /></td>
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
    <td><img width="500" alt="직원 관리_데스크톱" src="https://github.com/user-attachments/assets/437b6276-10f2-4bae-a76b-0dab7fc08a09" /></td>
    <td><img width="250" alt="직원 관리_모바일" src="https://github.com/user-attachments/assets/d8dc4f8f-da36-4496-871d-f3e8db61c5d0" /></td>
  </tr>
</table>

---

## ERD

<img width="2000" height="762" alt="ERD" src="https://github.com/user-attachments/assets/ac81983b-91a7-4f3c-b844-508fddf8f7b8" />
