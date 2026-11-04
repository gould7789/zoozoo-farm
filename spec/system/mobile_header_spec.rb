require "rails_helper"

# 모바일 폭에서 제목이 보조 동작 버튼에 밀려나지 않는지 본다.
# 판단 근거는 .claude/rules/notes/header-actions.md
RSpec.describe "모바일 헤더", type: :system do
  let(:admin) { create(:user, :admin, name: "관리자") }
  # 시드의 실제 관 이름 중 가장 긴 것 — 짧은 이름으로는 눌림이 재현되지 않는다
  let(:zone)  { Zone.create!(name: "야외동물체험관") }

  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 812 ]
    force_mobile_viewport
    sign_in_as(admin)
  end

  # 글자가 요소 폭 안에 다 들어가는가. truncate 가 걸린 제목은 넘치지 않고 수축하므로
  # 「가로 스크롤이 생겼는가」로는 영원히 잡히지 않는다
  def h1_fits?
    page.evaluate_script(<<~JS)
      (() => {
        const h = document.querySelector("h1");
        return h.scrollWidth <= Math.ceil(h.getBoundingClientRect().width) + 1;
      })()
    JS
  end

  describe "관 상세 헤더" do
    before { create(:animal, zone: zone, species: "알파카", name: "뭉치") }

    it "375px 에서 관 이름이 버튼에 밀려나지 않는다" do
      visit_mobile zone_path(zone)

      expect(page).to have_css("h1", text: "야외동물체험관")
      expect(h1_fits?).to be(true), "관 이름이 잘렸다 — 보조 동작이 헤더 폭을 먹고 있다"
    end

    it "보조 동작은 메뉴 안에 있고 주 동작은 밖에 있다" do
      visit_mobile zone_path(zone)

      # 「추가」는 접히지 않는다
      expect(page).to have_link("추가")
      # Excel 과 카테고리 관리는 메뉴를 열어야 나온다
      expect(page).to have_no_link("Excel")
      click_reliably "더보기"
      expect(page).to have_link("Excel")
      expect(page).to have_button("카테고리 관리")
    end

    it "메뉴가 ESC 로 닫힌다" do
      visit_mobile zone_path(zone)
      click_reliably "더보기"
      expect(page).to have_link("Excel")

      # keydown 을 DOM 에 직접 일으킨다. send_keys 는 body·browser.action·버튼 어디로
      # 보내도 실측 1/10 가량 유실됐다 — 우리 핸들러가 아니라 Selenium 의 키 전달 쪽이다.
      # 포기하는 것은 「브라우저가 ESC 를 document 로 올리는가」뿐이고 그건 표준 동작이다.
      # click_reliably 가 좌표 판정을 포기한 것과 같은 성격이다 (common/testing.md)
      page.execute_script(
        "document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))")
      expect(page).to have_no_link("Excel")
    end
  end

  describe "기록 목록 헤더" do
    it "매출 기록도 같은 규칙을 따른다" do
      create(:sales_record, created_by: admin)
      visit_mobile sales_path

      expect(page).to have_link("추가")
      expect(page).to have_no_link("Excel")
      click_reliably "더보기"
      expect(page).to have_link("Excel")
    end
  end
end
