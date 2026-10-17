# system spec用のヘルパーメソッド
# rails_helperでtype: :systemのスペックにインクルードされる
module SystemHelpers
  # request specのsign_inはpost login_pathでセッションを作るため、
  # 実ブラウザを操作するsystem specでは使えない。ログイン画面を実際に通す。
  # パスワードはfactoryの固定値"password123"を使用
  def sign_in_as(user)
    visit login_path
    fill_in_reliably "이메일", with: user.email
    fill_in_reliably "비밀번호", with: "password123"
    click_button "로그인"

    # click_buttonはTurboの遷移を待たずに返る。ここで待たないと
    # セッションが確立する前に次のvisitが走り、ログイン画面に弾かれる
    expect(page).to have_current_path(root_path)
  end

  # fill_inは入力が反映されたかを返さない。実測では12回に1回ほど取りこぼす。
  #
  # ログインフォームは両方の項目がrequiredなので、空のまま送信ボタンを押すと
  # ブラウザ側の検証で送信自体が止まる。サーバーには何も届かず、エラー表示も
  # 出ないまま画面が固まるため、後続の単語が「要素が見つからない」など
  # 原因と無関係な形で失敗する。
  #
  # 値を読み直して確かめ、入っていなければ入れ直す。
  # evaluate_scriptで直接valueを書かないのは、実際の入力経路を飛ばすと
  # このフォームが人の操作で使える状態かを検証できなくなるため
  # <dialog>をshowModal()で開いた直後のクリックは、遅い環境でハンドラに届かない
  # ことがある。CPUを20倍遅くした実測で8回に1回ほど、click_buttonが例外を出さずに
  # 終わるのにStimulusのアクションが走らなかった（showModalまでのログは残り、
  # ハンドラ入口のログが無い）。CIで再現していたのもこれ。
  #
  # 押した結果が現れず、かつダイアログがまだ開いているなら押し直す。
  # 閉じているのに結果が出ていなければ別の原因なので、そのまま失敗させる
  def click_in_dialog(label)
    2.times do
      # 座標を使わずDOMのclickを直接起こす。
      # Seleniumの通常のクリックは要素の中心座標を計算して押すが、
      # showModal()でトップレイヤーに出たダイアログではこれが外れることがあり、
      # click_buttonが例外を出さずに終わるのにハンドラが走らない状態になる。
      # CPUを20倍遅くした実測で8回に1回ほど再現し、押し直しても直らなかった。
      #
      # 実際のclickイベントとStimulusのアクションは通るので、
      # 失うのはブラウザの当たり判定だけ。そこはこのspecの検証対象ではない
      find(:button, label).execute_script("this.click()")
      return if yield
    end

    raise "ダイアログの操作が反映されませんでした: #{label}"
  end

  def fill_in_reliably(locator, with:)
    3.times do
      fill_in locator, with: with
      return if find_field(locator).value == with
    end

    raise "入力が反映されませんでした: #{locator}"
  end
end
