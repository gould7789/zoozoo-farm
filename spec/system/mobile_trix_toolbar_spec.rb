require "rails_helper"

# 모바일에서 Trix 툴바가 1줄로 접히는지 본다.
# 판단 근거는 .claude/rules/notes/notice.md 의 「모바일에서는 1줄로 접는다」
RSpec.describe "모바일 Trix 툴바", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 812 ]
    force_mobile_viewport
    sign_in_as(create(:user, :admin))
  end

  # 툴바가 몇 줄인지는 「보이는 버튼이 한 행에 들어가는가」로 본다.
  # 버튼 수를 세면 숨긴 버튼도 DOM 에 있어 통과한다 — 존재와 표시는 다른 축이다
  def toolbar_rows
    page.evaluate_script(<<~JS)
      (() => {
        const btns = [...document.querySelectorAll("trix-toolbar .trix-button-row button")]
          .filter(b => b.offsetParent !== null);
        return new Set(btns.map(b => Math.round(b.getBoundingClientRect().top))).size;
      })()
    JS
  end

  it "모바일에서 1줄이고 굵게·목록·첨부만 보인다" do
    visit_mobile new_notice_path

    expect(page).to have_css("trix-toolbar")
    expect(toolbar_rows).to eq(1)
    %w[bold bullet-list attach].each do |icon|
      expect(page).to have_css(".trix-button--icon-#{icon}", visible: :visible)
    end
    %w[italic strike link quote code number-list].each do |icon|
      expect(page).to have_no_css(".trix-button--icon-#{icon}", visible: :visible)
    end
  end

  # QA 에서 나온 두 가지. 둘 다 Trix 자체 CSS 와 부딪혀 생겼다
  it "서식 버튼은 왼쪽에 모이고 「⋯」 만 오른쪽 끝에 붙는다" do
    visit_mobile new_notice_path

    gaps = page.evaluate_script(<<~JS)
      (() => {
        const row = document.querySelector("trix-toolbar .trix-button-row");
        const vis = [...row.children].filter(g => g.offsetParent !== null);
        const r = g => g.getBoundingClientRect();
        return {
          // 서식 버튼끼리의 간격 — Trix 의 space-between 이 살아 있으면 크게 벌어진다
          tools: Math.round(r(vis[1]).left - r(vis[0]).right),
          // 「⋯」 가 행의 오른쪽 끝에 닿는가
          toRight: Math.round(r(row).right - r(vis[vis.length - 1]).right)
        };
      })()
    JS

    expect(gaps["tools"]).to be < 16
    expect(gaps["toRight"]).to be < 4
  end

  it "툴바와 입력창이 붙지 않는다 — 포커스 링이 아이콘에 닿았다" do
    visit_mobile new_notice_path

    gap = page.evaluate_script(<<~JS)
      (() => {
        const t = document.querySelector("trix-toolbar").getBoundingClientRect();
        const e = document.querySelector("trix-editor").getBoundingClientRect();
        return Math.round(e.top - t.bottom);
      })()
    JS

    # 포커스 링이 box-shadow 2px 라 그보다 넉넉해야 한다
    expect(gap).to be >= 4
  end

  it "펼침 버튼을 눌러도 에디터에서 포커스가 나가지 않는다" do
    visit_mobile new_notice_path
    page.execute_script('document.querySelector("trix-editor").focus()')

    # execute_script("this.click()") 로는 못 잡는다 — 포커스를 옮기지 않기 때문이다.
    # tabIndex = -1 은 Tab 순서에서만 빼므로 실제 클릭으로 눌러야 드러난다
    find("[data-trix-toolbar-toggle]").click

    expect(page.evaluate_script("document.activeElement.tagName")).to eq("TRIX-EDITOR")
  end

  it "펼치면 나머지 버튼이 나오고 서식이 실제로 걸린다" do
    visit_mobile new_notice_path
    expect(page).to have_no_css(".trix-button--icon-italic", visible: :visible)

    find("[data-trix-toolbar-toggle]").execute_script("this.click()")
    expect(page).to have_css(".trix-button--icon-italic", visible: :visible)

    # 버튼이 Trix 의 핸들러에 닿는지 — 팝업으로 빼냈다면 여기서 떨어진다
    page.execute_script(<<~JS)
      const e = document.querySelector("trix-editor");
      // 포커스를 줘야 Trix 가 선택 범위를 문서 선택과 맞춘다 —
      // 안 주면 setSelectedRange 가 내부 값만 바꾸고 서식이 아무 데도 안 걸린다
      e.focus();
      e.editor.insertString("기울임 확인");
      e.editor.setSelectedRange([0, "기울임 확인".length]);
    JS
    # Trix 는 서식 버튼에 click 이 아니라 mousedown 을 건다
    # (trix.js 의 ToolbarController — attributeButtonSelector 에 handleEvent("mousedown")).
    # click_reliably 나 this.click() 으로는 이 핸들러에 영원히 닿지 않는다
    find(".trix-button--icon-italic").execute_script(
      "this.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))")

    expect(page).to have_css("trix-editor em", text: "기울임 확인")
  end
end
