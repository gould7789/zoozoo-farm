require "rails_helper"

# 동물 상세의 최근 기록 카드가 모바일 폭에서 읽히는지 본다.
# 표시 내용 자체는 spec/requests/animals_spec.rb 가 본다 — 여기는 배치만 본다.
# 판단 근거는 .claude/rules/notes/animal-lifecycle.md
RSpec.describe "동물 상세의 최근 기록", type: :system do
  let(:staff)  { create(:user, name: "사육사") }
  let(:zone)   { Zone.create!(name: "야외동물체험관") }
  # 긴 먹이 이름 — 짧은 값으로는 폭이 모자란 상황이 재현되지 않는다
  let(:animal) { create(:animal, zone: zone, species: "알파카", name: "뭉치") }

  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 812 ]
    force_mobile_viewport
    sign_in_as(staff)
  end

  # 행 영역이 제 폭 안에 들어가는가. truncate 가 걸린 요소는 넘치지 않고 수축하므로
  # 「가로 스크롤이 생겼는가」로는 잡히지 않는다 (common/testing.md).
  # querySelector 는 첫 번째만 보므로 카드 두 개를 다 재고, 안 맞는 것을 이름으로 돌려준다
  def overflowing_rows
    page.evaluate_script(<<~JS)
      (() => {
        const bad = [];
        document.querySelectorAll(".divide-y").forEach((el) => {
          const need = el.scrollWidth;
          const have = Math.ceil(el.getBoundingClientRect().width) + 1;
          if (need > have) bad.push(`${el.closest("div.bg-white").innerText.split("\\n")[0]}: ${need}px > ${have}px`);
        });
        return bad;
      })()
    JS
  end

  def horizontal_overflow?
    page.evaluate_script("document.documentElement.scrollWidth > window.innerWidth + 1")
  end

  it "375px 에서 기록 행이 가로로 넘치지 않는다" do
    create(:health_record, animal: animal, created_by: staff,
           recorded_on: Date.current, condition: :caution, weight_kg: 1234.56)
    create(:feeding_record, animal: animal, created_by: staff,
           fed_at: Time.current, food_type: "알파카용 혼합 건초 펠렛", amount_g: 12_345)

    visit_mobile zone_animal_path(zone, animal)

    expect(page).to have_text("건강 기록")
    expect(page).to have_text("먹이 기록")
    expect(horizontal_overflow?).to be(false), "최근 기록 카드가 화면 폭을 넘겼다"
    # 긴 먹이 이름이 truncate 로 줄어드는 것은 정상이고, 행 영역이 안 밀리는지가 기준이다
    expect(overflowing_rows).to be_empty
  end

  it "「전체 보기」의 터치 영역이 44px 이상이다" do
    visit_mobile zone_animal_path(zone, animal)

    heights = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('a[aria-label$="전체 보기"]'))
           .map((a) => Math.round(a.getBoundingClientRect().height))
    JS

    expect(heights.size).to eq(2)
    expect(heights).to all(be >= 44), "터치 영역이 모자라다 — #{heights.inspect}"
  end

  it "기록이 없으면 빈 상태 문구가 보인다" do
    visit_mobile zone_animal_path(zone, animal)

    expect(page).to have_text("아직 기록이 없습니다", count: 2)
    expect(horizontal_overflow?).to be(false)
  end

  # aria-label 로 둘을 가른다. 같은 「전체 보기」 두 개면 스크린 리더로 구분되지 않는다
  it "「전체 보기」로 건강 기록 목록에 간다" do
    visit_mobile zone_animal_path(zone, animal)

    click_reliably "건강 기록 전체 보기"
    expect(page).to have_current_path(zone_animal_health_logs_path(zone, animal))
  end

  it "「전체 보기」로 먹이 기록 목록에 간다" do
    visit_mobile zone_animal_path(zone, animal)

    click_reliably "먹이 기록 전체 보기"
    expect(page).to have_current_path(zone_animal_feeding_logs_path(zone, animal))
  end
end
