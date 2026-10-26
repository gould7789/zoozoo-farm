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
    click_reliably "로그인"

    # クリックはTurboの遷移を待たずに返る。ここで待たないと
    # セッションが確立する前に次のvisitが走り、ログイン画面に弾かれる
    expect(page).to have_current_path(root_path)
  end

  # Seleniumの座標ベースのクリックは、この構成（Turbo + Stimulus）で
  # ハンドラに届かないことが一定の確率で起きる。実測では1〜2割。
  # ログイン送信・ダイアログのボタン・一覧のボタンのいずれでも再現し、
  # 例外も出ず、待ち時間を2秒から5秒に伸ばしても失敗率は変わらなかった
  # （3/15のまま）。つまり遅延ではなく取りこぼしである。
  #
  # 座標を介さずDOMのclickを直接起こす。実際のclickイベントとハンドラ、
  # フォーム送信は通るので、失うのはブラウザの当たり判定だけ。
  # そこはこのspecの検証対象ではなく、人の目視で担保する
  def click_reliably(label)
    find(:button, label).execute_script("this.click()")
  end

  # ダイアログ内のボタンを押し、結果が現れるまで確かめる。
  #
  # confirm()は#showPreviewの後に#closeを呼ぶため、プレビューが見えた時点でも
  # まだ開いていることがある。モーダル表示中は背後の要素がinertになり、
  # そこへのクリックが無視されて原因の分かりにくい失敗になるので、
  # 閉じきるまで待ってから返す。
  #
  # 結果が出ないままダイアログが閉じていたら押し直しても意味がない。
  # 閉じたダイアログの中のボタンは見つからず、待ち時間ぶん止まった末に
  # ElementNotFoundになって、本当の原因が分からなくなる
  def click_in_dialog(label)
    2.times do
      click_reliably label
      return if yield && page.has_no_css?("dialog[open]", visible: :all)
      break unless page.has_css?("dialog[open]", visible: :all, wait: 0)
    end

    raise "ダイアログの操作が反映されませんでした: #{label}"
  end

  # fill_inは入力が反映されたかを返さない。Seleniumのsend_keysは
  # 要素にフォーカスが当たっていても取りこぼすことがあり、実測では
  # フィールドが空のまま3回連続で失敗した。
  #
  # ログインフォームは両方の項目がrequiredなので、空のまま送信すると
  # ブラウザ側の検証で送信自体が止まる。サーバーには何も届かず、
  # エラー表示も出ないまま画面が固まるため、後続の単言が
  # 「要素が見つからない」など原因と無関係な形で失敗する。
  #
  # 毎回find_fieldをやり直すのは、要素を握ったまま再試行すると
  # DOMが差し替わった時にStaleElementReferenceErrorになり、
  # この関数が吸収しようとしている取りこぼしと同じ形で落ちるため
  def fill_in_reliably(locator, with:)
    2.times do
      field = find_field(locator)
      field.set(with)
      return if field.value == with
    end

    # それでも届かない場合はJSで値を入れ、inputイベントを発火させる。
    # ここで失うのは「このフォームがキー入力を受け付けるか」の検証だが、
    # それはログイン自体のテスト（spec/requests/sessions_spec.rb）の担当であり、
    # このspecの検証対象ではない。ログインで落ちると原因の分かりにくい失敗になる
    field = find_field(locator)
    field.execute_script("this.value = arguments[0]; this.dispatchEvent(new Event('input', { bubbles: true }))", with)
    raise "入力が反映されませんでした: #{locator}" unless field.value == with
  end
end
