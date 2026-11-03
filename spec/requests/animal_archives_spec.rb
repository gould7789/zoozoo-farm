# AnimalArchivesController — 내보낸 개체 보관
require "rails_helper"

RSpec.describe "AnimalArchives", type: :request do
  let(:zone)  { create(:zone) }
  let(:staff) { create(:user) }

  it "비로그인은 로그인 화면으로 보낸다" do
    get archive_path
    expect(response).to redirect_to(login_path)
  end

  context "로그인 상태" do
    before { sign_in(staff) }

    # 조회는 Staff 공통이다 — 동물 상세가 이미 공통이고 「그 아이 언제 죽었지」는 둘 다 묻는다
    it "Staff 도 열 수 있다" do
      get archive_path
      expect(response).to have_http_status(:ok)
    end

    it "내보낸 개체만 보여준다" do
      create(:animal, :exited, zone: zone, species: "호랑이")
      create(:animal, zone: zone, species: "사막여우")

      get archive_path

      expect(response.body).to include("호랑이")
      expect(response.body).not_to include("사막여우")
    end

    it "사유로 거를 수 있다" do
      create(:animal, :exited, zone: zone, species: "호랑이")
      create(:animal, :exited, zone: zone, species: "토끼",
             exit_reason: :transferred, exited_on: Date.current)

      get archive_path(reason: "transferred")

      expect(response.body).to include("토끼")
      expect(response.body).not_to include("호랑이")
    end

    # enum 에 없는 값을 where 에 넘기면 ArgumentError 로 떨어진다 (common/rails.md)
    it "사유가 enum 밖이면 전체를 보여준다" do
      create(:animal, :exited, zone: zone, species: "호랑이")

      get archive_path(reason: "교환")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("호랑이")
    end

    # notices_spec 과 같은 모양 — 파일마다 둔다
    def query_count
      count = 0
      sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
        count += 1 unless payload[:name].to_s =~ /SCHEMA|TRANSACTION/
      end
      begin
        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(sub)
      end
      count
    end

    def exited_with_photo
      animal = create(:animal, :exited, zone: zone)
      animal.photo.attach(io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
                          filename: "a.jpg", content_type: "image/jpeg")
      animal
    end

    it "개체가 늘어도 쿼리 수가 늘지 않는다" do
      exited_with_photo
      few = query_count { get archive_path }

      3.times { exited_with_photo }
      many = query_count { get archive_path }

      expect(many).to eq(few)
    end
  end
end
