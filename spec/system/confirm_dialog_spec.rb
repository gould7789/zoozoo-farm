require "rails_helper"

# 확인 다이얼로그는 두 모드로 쓰인다 — 실제 확인과 안내.
# 안내 모드에서 빨강이면 아무 일도 안 일어나는데 위험해 보인다 (notes/color.md)
RSpec.describe "확인 다이얼로그", type: :system do
  let(:admin) { create(:user, :admin, name: "김관리") }

  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
    sign_in_as(admin)
  end

  # 클래스명이 아니라 실제로 칠해진 색을 본다 — 클래스가 빌드된 CSS 에
  # 안 들어갔으면 클래스 단언은 통과하면서 화면은 무색이 된다
  def confirm_button_color
    page.evaluate_script(<<~JS)
      getComputedStyle(document.querySelector("#confirm-dialog button[value=confirm]")).backgroundColor
    JS
  end

  # 기대값을 문자열로 박지 않는다. Tailwind v4 는 oklch 로 내고 포맷이 바뀔 수 있어서,
  # 그 클래스를 실제로 칠한 요소에서 값을 읽어 비교한다
  def color_of(tailwind_class)
    page.evaluate_script(<<~JS)
      (() => {
        const el = document.createElement("div");
        el.className = #{tailwind_class.inspect};
        document.body.appendChild(el);
        const c = getComputedStyle(el).backgroundColor;
        el.remove();
        return c;
      })()
    JS
  end

  it "안내 모드에서는 확인 버튼이 빨강이 아니다" do
    staff  = create(:user, name: "박알바")
    animal = create(:animal, zone: Zone.create!(name: "야외동물체험관"))
    create(:health_record, animal: animal, created_by: staff)

    visit admin_members_path
    find("[data-controller~='blocked-delete']", match: :first).execute_script("this.click()")
    expect(page).to have_css("#confirm-dialog[open]")

    expect(confirm_button_color).to eq(color_of("bg-gray-700"))
    expect(confirm_button_color).not_to eq(color_of("bg-red-600"))
  end

  it "실제 확인에서는 확인 버튼이 빨강이다" do
    create(:notice, created_by: admin, title: "지울 공지")

    visit notices_path
    # 「삭제」로 집는다 — 셀렉터로 잡으면 어느 버튼을 눌렀는지가 스펙에 안 남는다
    click_reliably "삭제"
    expect(page).to have_css("#confirm-dialog[open]")

    expect(confirm_button_color).to eq(color_of("bg-red-600"))
  end
end
