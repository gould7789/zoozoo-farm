# system spec用のヘルパーメソッド
# rails_helperでtype: :systemのスペックにインクルードされる
module SystemHelpers
  # request specのsign_inはpost login_pathでセッションを作るため、
  # 実ブラウザを操作するsystem specでは使えない。ログイン画面を実際に通す。
  # パスワードはfactoryの固定値"password123"を使用
  def sign_in_as(user)
    visit login_path
    fill_in "이메일", with: user.email
    fill_in "비밀번호", with: "password123"
    click_button "로그인"

    # click_buttonはTurboの遷移を待たずに返る。ここで待たないと
    # セッションが確立する前に次のvisitが走り、ログイン画面に弾かれる
    expect(page).to have_current_path(root_path)
  end
end
