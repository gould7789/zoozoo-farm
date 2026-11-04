# system spec 드라이버 설정
# CI 의 ubuntu-latest 에 Chrome 이 있고 Selenium Manager 가 chromedriver 를
# 알아서 준비하므로 추가 설치 단계가 필요 없다.
# 대기 시간과 화면 크기의 근거는 .claude/rules/common/testing.md
Capybara.default_max_wait_time = 5
# 아이콘만 있는 버튼은 텍스트가 없어 aria-label 로 찾는다 (shared/_action_menu 의 「더보기」)
Capybara.enable_aria_label = true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
  end
end
