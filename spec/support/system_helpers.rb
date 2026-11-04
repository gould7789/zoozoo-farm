# system spec 용 헬퍼 — rails_helper 가 type: :system 에 include 한다
# 각 헬퍼가 무엇을 흡수하고 무엇을 포기하는지는 .claude/rules/common/testing.md
module SystemHelpers
  # 요청 스펙의 sign_in 은 post 로 세션을 만들어 실제 브라우저에서는 쓸 수 없다.
  # 로그인 화면을 실제로 통과한다. 비밀번호는 팩토리의 고정값 "password123"
  def sign_in_as(user)
    visit login_path
    fill_in_reliably "이메일", with: user.email
    fill_in_reliably "비밀번호", with: "password123"
    click_reliably "로그인"

    # 클릭은 Turbo 의 전환을 기다리지 않고 돌아온다. 여기서 안 기다리면
    # 세션이 서기 전에 다음 visit 이 돌아 로그인 화면으로 튕긴다
    expect(page).to have_current_path(root_path)
  end

  # 모바일 폭을 만든다. screen_size 로는 안 된다 — headless Chrome 의 창 최소 폭이
  # 500px 이라 clientWidth 가 500 으로 잡힌다. 반드시 visit 전에 부른다:
  # 방문 뒤에 바꾸면 500 으로 그린 뒤 375 로 재배치되는 경합이 생긴다
  def force_mobile_viewport(width: 375, height: 812)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: width, height: height, deviceScaleFactor: 2, mobile: true)
  end

  # 폭을 재는 단언에는 Capybara 의 재시도가 듣지 않으므로, 배치가 끝난 것을
  # 눈에 보이는 요소로 먼저 확인한다
  def visit_mobile(path)
    visit path
    expect(page).to have_css("h1", wait: 5)
  end

  # 좌표를 거치지 않고 DOM 의 click 을 직접 일으킨다.
  # 실측 1~2할 유실 — 대기를 2초에서 5초로 늘려도 실패율이 같았다(3/15 그대로)
  def click_reliably(label)
    find(:button, label).execute_script("this.click()")
  end

  # 다이얼로그 안의 버튼을 누르고, 결과가 나오고 닫히기까지 확인한다.
  # confirm() 이 #showPreview 뒤에 #close 를 부르므로 미리보기가 보여도 아직 열려 있을 수 있다
  def click_in_dialog(label)
    2.times do
      click_reliably label
      return if yield && page.has_no_css?("dialog[open]", visible: :all)
      break unless page.has_css?("dialog[open]", visible: :all, wait: 0)
    end

    raise "다이얼로그 조작이 반영되지 않았습니다: #{label}"
  end

  # fill_in 은 입력이 반영됐는지 돌려주지 않는다. send_keys 가 포커스가 맞아도
  # 흘리는 일이 있어, 실측으로 칸이 빈 채 3회 연속 실패했다.
  # 매번 find_field 를 다시 하는 이유는 StaleElementReferenceError 를 피하기 위해서다
  def fill_in_reliably(locator, with:)
    2.times do
      field = find_field(locator)
      field.set(with)
      return if field.value == with
    end

    # 그래도 안 들어가면 JS 로 값을 넣고 input 이벤트를 띄운다.
    # 여기서 잃는 「키 입력을 받는가」의 검증은 spec/requests/sessions_spec.rb 의 몫이다
    field = find_field(locator)
    field.execute_script("this.value = arguments[0]; this.dispatchEvent(new Event('input', { bubbles: true }))", with)
    raise "입력이 반영되지 않았습니다: #{locator}" unless field.value == with
  end
end
