require "rails_helper"

# 내비게이션의 「지금 여기」 표시
#
# 색만으로는 적록색약에게 전달되지 않는다. aria-current 는 스크린리더용이고,
# 화면 쪽 단서(상단 바)는 CSS 라 여기서 못 본다 — QA 의 스크린샷이 그쪽을 맡는다.
# 판단 근거는 .claude/rules/notes/color.md 의 「색이 유일한 단서가 아니다」
RSpec.describe "내비게이션 현재 위치", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }
  let(:zone)  { create(:zone) }

  # 하단 탭과 사이드바가 같은 레이아웃에 함께 있으므로 한 화면에 두 번 붙는다.
  # 그래서 「몇 개인가」가 아니라 「어디를 가리키는가」를 본다
  def current_hrefs
    Nokogiri::HTML5(response.body)
      .css("a[aria-current='page']")
      .map { |a| a["href"] }
      .uniq
  end

  context "Admin" do
    before { sign_in(admin) }

    it "관 목록에서는 관 목록이 현재다" do
      get zones_path
      expect(current_hrefs).to contain_exactly(zones_path)
    end

    # root 는 zones#index 이고 로그인 직후 여기로 온다. 경로가 "/" 라
    # zones_path 와 문자열이 달라 탭이 하나도 안 켜져 있었다
    it "루트에서도 관 목록이 현재다" do
      get root_path
      expect(current_hrefs).to contain_exactly(zones_path)
    end

    # 하위 경로에서도 유지된다 — request.path.start_with?("#{path}/")
    it "관 상세에서도 관 목록이 현재다" do
      get zone_path(zone)
      expect(current_hrefs).to contain_exactly(zones_path)
    end

    it "공지 목록에서는 공지가 현재다" do
      get notices_path
      expect(current_hrefs).to contain_exactly(notices_path)
    end

    it "내 정보에서는 내 정보가 현재다" do
      get account_path
      expect(current_hrefs).to contain_exactly(account_path)
    end

    it "관리 허브에서는 관리가 현재다" do
      get admin_dashboard_path
      expect(current_hrefs).to contain_exactly(admin_dashboard_path)
    end

    # 하단 탭의 「관리」는 매출·지출·직원 관리에서도 켜진다(also_active_on).
    # 사이드바에는 매출 항목이 따로 있으므로 둘이 같이 켜지는 것이 맞다
    it "매출에서는 하단 탭의 관리와 사이드바의 매출이 함께 현재다" do
      get sales_path
      expect(current_hrefs).to contain_exactly(admin_dashboard_path, sales_path)
    end
  end

  context "Staff" do
    before { sign_in(staff) }

    # Staff 에게는 관리 탭이 없다. 없는 항목이 현재가 되는 일도 없어야 한다
    it "관 목록이 현재이고 관리 허브는 나오지 않는다" do
      get zones_path

      expect(current_hrefs).to contain_exactly(zones_path)
      expect(response.body).not_to include(admin_dashboard_path)
    end
  end
end
