# 프로필 사진 자르기 화면의 표시 상태.
# 보는 건 「누른 뒤 어느 요소가 보이고 어느 것이 숨는가」뿐이다.
# 끌기·핀치·canvas 의 그림 내용은 검증하지 않는다 — 결함 3건이 전부
# 표시 상태 전이에서 났고 끌기에서는 나지 않았다. 2축 상태는 notes/animal-photo.md
require "rails_helper"

RSpec.describe "동물 프로필 사진", type: :system do
  let(:zone)   { create(:zone) }
  let(:admin)  { create(:user, :admin) }
  let(:animal) { create(:animal, zone: zone) }

  # 요소를 hidden 속성으로 가르므로, visible 로 보이는 것만 대상으로 한다.
  #
  # page.all 은 count 계열 옵션이 없으면 기다리지 않고 즉시 돌아온다.
  # toBlob 과 디코드 실패 직후는 그리기가 한 박자 늦어 느린 CI 에서 흘린다.
  # have_css / have_no_css 는 조건이 찰 때까지 다시 시도하며 기다린다
  def target_css(target) = "[data-photo-crop-target='#{target}']"

  def expect_visible(target)
    expect(page).to have_css(target_css(target), visible: true)
  end

  def expect_hidden(target)
    expect(page).to have_no_css(target_css(target), visible: true)
  end

  # 다이얼로그 안의 버튼은 눌러도 닿지 않을 수 있어 결과로 확인한다
  def confirm_crop
    click_in_dialog("완료") { page.has_css?(target_css("preview"), visible: true, wait: 3) }
  end

  def cancel_crop
    click_in_dialog("취소") { page.has_no_css?(target_css("preview"), visible: true, wait: 3) }
  end

  def choose_photo(filename)
    # file_field 의 name 으로 특정한다 — 라벨로 찾으면 자르기 화면의 요소와 섞인다
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
    # 미저장 선택이 있는 동안 서버 삭제를 내면, 취소하려다 누른다
    expect_hidden("destroy")
  end

  # 결함 1 — cancel() 이 표시 상태를 되돌리지 않았다.
  # 두 번째 선택을 취소하면 첫 장의 미리보기가 남고, 보내도 아무것도 첨부되지 않는다
  it "두 번째 선택을 취소하면 이전 미리보기가 사라지고 원래 상태로 돌아온다" do
    choose_photo("animal.jpg")
    confirm_crop
    expect_visible("preview")

    choose_photo("animal2.jpg")
    cancel_crop

    expect_hidden("preview")
    expect_hidden("clear")
    # 저장된 사진과 그 삭제 버튼이 돌아오는지
    expect_visible("destroy")
  end

  # 결함 2 — 디코드 실패 때 표시를 되돌리지 않았다.
  # HEIC 를 쓰면 브라우저·OS 에 따라 읽혀 환경에 의존하는 테스트가 되므로,
  # 이미지가 아닌 파일에 .jpg 를 붙여 확실히 실패시킨다
  it "미리보기를 만들 수 없는 파일을 고르면 선택 취소 버튼만 남는다" do
    choose_photo("not_an_image.jpg")

    expect_hidden("preview")
    # 취소할 수단은 남긴다
    expect_visible("clear")
    # 서버 삭제가 나와 있으면 「선택 취소」인 줄 알고 저장된 사진을 지운다
    expect_hidden("destroy")
  end

  it "선택 취소를 누르면 저장된 사진과 삭제 버튼이 돌아온다" do
    choose_photo("animal.jpg")
    confirm_crop

    click_reliably "사진 삭제"   # 미저장 선택에 대해서는 취소로 작동한다

    expect_hidden("preview")
    expect_visible("destroy")
  end
end
