# プロフィール写真の切り抜き画面の表示状態を検証するsystem spec
#
# ここで見るのは「クリックの後、どの要素が見えてどれが隠れるか」だけ。
# ドラッグ移動・ピンチ拡大・canvasの描画内容は検証しない。
# 不具合3件がすべて表示状態の遷移で起きており、ドラッグでは起きていないため。
require "rails_helper"

RSpec.describe "동물 프로필 사진", type: :system do
  let(:zone)   { create(:zone) }
  let(:admin)  { create(:user, :admin) }
  let(:animal) { create(:animal, zone: zone) }

  # 要素はhidden属性で出し分けるため、visible指定で見えているものだけを対象にする。
  #
  # page.allはcount系のオプションが無いと待たずに即座に返る。
  # toBlobやデコード失敗の直後は描画が一拍遅れるため、遅いCIで取りこぼす。
  # have_css / have_no_cssは条件が満たされるまで再試行して待つ
  def target_css(target) = "[data-photo-crop-target='#{target}']"

  def expect_visible(target)
    expect(page).to have_css(target_css(target), visible: true)
  end

  def expect_hidden(target)
    expect(page).to have_no_css(target_css(target), visible: true)
  end

  # ダイアログ内のボタンは押しても届かないことがあるため結果で確かめる
  def confirm_crop
    click_in_dialog("완료") { page.has_css?(target_css("preview"), visible: true, wait: 3) }
  end

  def cancel_crop
    click_in_dialog("취소") { page.has_no_css?(target_css("preview"), visible: true, wait: 3) }
  end

  def choose_photo(filename)
    # file_fieldのname属性で特定する。ラベル経由だと切り抜き画面の要素と紛れる
    attach_file "animal[photo]", Rails.root.join("spec/fixtures/files/#{filename}")
  end

  before do
    animal.photo.attach(fixture_file_upload("animal.jpg", "image/jpeg"))
    sign_in_as(admin)
    visit edit_zone_animal_path(zone, animal)
  end

  it "자르기를 완료하면 미리보기가 나오고 서버 삭제 버튼은 숨는다" do
    choose_photo("animal.jpg")
    confirm_crop

    expect_visible("preview")
    expect_visible("clear")
    # 未保存の選択がある間にサーバー削除を出すと、取り消しのつもりで押してしまう
    expect_hidden("destroy")
  end

  # 不具合1 — cancel()が表示状態を戻していなかった。
  # 2回目の選択を取り消すと1枚目のプレビューが残り、送信しても何も添付されない
  it "두 번째 선택을 취소하면 이전 미리보기가 사라지고 원래 상태로 돌아온다" do
    choose_photo("animal.jpg")
    confirm_crop
    expect_visible("preview")

    choose_photo("animal2.jpg")
    cancel_crop

    expect_hidden("preview")
    expect_hidden("clear")
    # 保存済みの写真とその削除ボタンが戻ること
    expect_visible("destroy")
  end

  # 不具合2 — デコード失敗時に表示を戻していなかった。
  # ここでHEICを使うとブラウザやOSによって読めてしまい環境依存のテストになるため、
  # 画像ではないファイルに.jpgを付けて確実に失敗させる
  it "미리보기를 만들 수 없는 파일을 고르면 선택 취소 버튼만 남는다" do
    choose_photo("not_an_image.jpg")

    expect_hidden("preview")
    # 取り消す手段は残す
    expect_visible("clear")
    # サーバー削除が出ていると「選択の取り消し」のつもりで保存済みの写真を消してしまう
    expect_hidden("destroy")
  end

  it "선택 취소를 누르면 저장된 사진과 삭제 버튼이 돌아온다" do
    choose_photo("animal.jpg")
    confirm_crop

    click_reliably "사진 삭제"   # 未保存の選択に対しては取り消しとして働く

    expect_hidden("preview")
    expect_visible("destroy")
  end
end
