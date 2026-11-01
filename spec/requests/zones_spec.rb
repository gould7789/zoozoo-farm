# ZonesController — 인증 제어와 목록의 쿼리 수
require "rails_helper"

RSpec.describe "Zones", type: :request do
  def query_count
    count = 0
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      count += 1 unless payload[:name].to_s =~ /SCHEMA|TRANSACTION/
    end
    begin
      yield
    ensure
      # ensure 가 없으면 블록이 예외를 던질 때 구독이 남아 뒤 테스트의 측정값이 흐트러진다
      ActiveSupport::Notifications.unsubscribe(sub)
    end
    count
  end

  describe "GET /zones" do
    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        get zones_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "로그인 상태" do
      before { sign_in(create(:user)) }

      it "200을 반환한다" do
        get zones_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /zones/:id" do
    let(:zone) { create(:zone) }

    context "비로그인" do
      it "로그인 화면으로 보낸다" do
        get zone_path(zone)
        expect(response).to redirect_to(login_path)
      end
    end

    context "로그인 상태" do
      before { sign_in(create(:user)) }

      it "200을 반환한다" do
        get zone_path(zone)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "홈의 최신 공지" do
    let(:staff) { create(:user) }

    # 본문의 저장 위치를 바꿀 때 여기 그리기를 빠뜨리면 행이 빈 채로 나온다.
    # 공지 목록과 달리 spec 이 없었다
    it "제목을 표시한다" do
      create(:notice, created_by: staff, title: "급수대 점검 예정")
      sign_in(staff)
      get zones_path
      expect(response.body).to include("급수대 점검 예정")
    end

    it "공지가 늘어도 쿼리 수가 늘지 않는다" do
      sign_in(staff)
      create(:notice, created_by: staff, title: "하나")
      few = query_count { get zones_path }

      3.times { |i| create(:notice, created_by: staff, title: "제목#{i}") }
      many = query_count { get zones_path }

      expect(many).to eq(few)
    end
  end

  describe "목록의 썸네일" do
    let(:zone) { create(:zone) }

    def create_animal_with_photo(category: nil)
      create(:animal, zone: zone, animal_category: category).tap do |animal|
        animal.photo.attach(fixture_file_upload("animal.jpg", "image/jpeg"))
      end
    end

    before { sign_in(create(:user)) }

    it "사진이 있는 동물은 proxy 경유 썸네일을 낸다" do
      create_animal_with_photo

      get zone_path(zone)

      expect(response.body).to include("/rails/active_storage/representations/proxy/")
    end

    # 첨부 선읽기가 없으면 동물마다 쿼리가 는다
    it "동물이 늘어도 쿼리 수가 늘지 않는다" do
      3.times { create_animal_with_photo }
      few = query_count { get zone_path(zone) }

      7.times { create_animal_with_photo(category: create(:animal_category, zone: zone)) }
      many = query_count { get zone_path(zone) }

      expect(many).to eq(few)
    end

    # @animals_by_category 를 만드는 자리는 zones#show 와 animal_categories 두 곳이다.
    # 이쪽을 빠뜨리면 카테고리 조작 뒤 다시 그릴 때만 N+1 이 난다 —
    # 평소에는 안 보이고 특정 조작 뒤에만 나타나 가장 알아채기 어렵다
    it "카테고리 조작 뒤 다시 그릴 때도 쿼리 수가 늘지 않는다" do
      sign_in(create(:user, :admin))
      # 토글 대상과 별개로 미분류 동물을 둔다. 토글하면 그 카테고리가 숨겨져
      # 소속 동물이 아코디언에서 사라지므로, 토글 대상에 동물을 넣으면
      # 사진을 참조하는 코드까지 닿지 않는다
      toggled = create(:animal_category, zone: zone, hidden: false)
      # Accept 헤더가 없으면 format.html 로 떨어져 리다이렉트되고,
      # 아코디언이 그려지지 않은 채 통과한다
      turbo = { headers: { "Accept" => "text/vnd.turbo-stream.html" } }

      3.times { create_animal_with_photo }
      few = query_count { patch toggle_zone_animal_category_path(zone, toggled), **turbo }

      7.times { create_animal_with_photo }
      many = query_count { patch toggle_zone_animal_category_path(zone, toggled), **turbo }

      expect(many).to eq(few)
    end
  end
end
