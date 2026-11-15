# xlsx 내보내기 5경로 — Admin 만 파일을 받는다
#
# 5경로를 한 파일에 모은 이유는 **빠뜨린 줄이 눈에 보이게** 하는 것이다.
# 컨트롤러 하나에서 권한 검사가 빠지면 에러 없이 Staff 에게 파일이 간다.
# 판단 근거는 .claude/rules/notes/xlsx-export.md
require "rails_helper"

# 지역변수로 두면 describe 블록이 클로저로 잡는다 — 상수는 전역을 오염시킨다.
# path·filename 을 람다로 두는 이유는 let 이 예제 안에서만 해결되기 때문이다
exports = [
  {
    label:    "동물 대장",
    path:     -> { export_zone_animals_path(zone) },
    filename: -> { "동물목록_#{zone.name}_#{Date.current}.xlsx" }
  },
  {
    label:    "건강 기록",
    path:     -> { export_zone_animal_health_logs_path(zone, animal) },
    filename: -> { "건강기록_#{animal.species}_#{Date.current}.xlsx" }
  },
  {
    label:    "먹이 기록",
    path:     -> { export_zone_animal_feeding_logs_path(zone, animal) },
    filename: -> { "먹이기록_#{animal.species}_#{Date.current}.xlsx" }
  },
  {
    label:    "매출 기록",
    path:     -> { export_sales_path },
    filename: -> { "매출기록_#{Date.current.year}년#{format('%02d', Date.current.month)}월.xlsx" }
  },
  {
    label:    "지출 기록",
    path:     -> { export_expenses_path },
    filename: -> { "지출기록_#{Date.current.year}년#{format('%02d', Date.current.month)}월.xlsx" }
  }
]

RSpec.describe "Xlsx 내보내기", type: :request do
  let(:admin)  { create(:user, :admin) }
  let(:staff)  { create(:user) }
  let(:zone)   { create(:zone) }
  let(:animal) { create(:animal, zone: zone) }

  # 각 경로가 빈 목록이 아니게 한다 — 0건이어도 파일은 나오지만,
  # 행이 있는 쪽이 리팩토링 전후의 바이트 비교에서 의미가 있다
  before do
    create(:health_record,  animal: animal, created_by: admin)
    create(:feeding_record, animal: animal, created_by: admin)
    create(:sales_record,   created_by: admin)
    create(:expense_record, created_by: admin)
  end

  XLSX_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  # 한글 파일명은 RFC 5987 의 filename*=UTF-8'' 쪽에 들어간다.
  # 같은 헤더의 filename= 는 ASCII 폴백이라 한글이 남지 않는다
  def downloaded_filename
    encoded = response.headers["Content-Disposition"][/filename\*=UTF-8''(\S+)/, 1]
    CGI.unescape(encoded)
  end

  exports.each do |export|
    describe export[:label] do
      context "비로그인" do
        before { get instance_exec(&export[:path]) }
        it_behaves_like "로그인이 필요하다"
      end

      context "Staff 가 내보내기를 시도" do
        before { sign_in(staff); get instance_exec(&export[:path]) }

        it_behaves_like "접근이 거부된다"

        it "파일을 받지 못한다" do
          expect(response.body).to be_empty
        end
      end

      context "Admin 이 내보내기" do
        before { sign_in(admin); get instance_exec(&export[:path]) }

        it "xlsx 파일을 받는다" do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq(XLSX_TYPE)
          expect(response.body.bytesize).to be > 0
        end

        it "파일명이 도메인의 말로 나온다" do
          expect(downloaded_filename).to eq(instance_exec(&export[:filename]))
        end
      end
    end
  end

  # 화면의 Excel 링크가 선택한 연월을 함께 넘긴다. 안 받으면 어느 달을 보고 있든
  # 최신 월이 나와 사용자가 받은 파일과 화면이 어긋난다
  describe "매출·지출은 화면에서 고른 연월을 받는다" do
    before do
      create(:sales_record, created_by: admin, sold_on: Date.new(2026, 4, 15), source: :vending_1)
      sign_in(admin)
    end

    it "지정한 연월이 파일명에 들어간다" do
      get export_sales_path(year: 2026, month: 4)

      expect(downloaded_filename).to eq("매출기록_2026년04월.xlsx")
    end
  end

  # 확장자가 사라져 Turbo 가 링크를 가로채게 됐다 — 실측 export 가 2번 돌았다.
  # `.xlsx` 는 Turbo 의 unvisitableExtensions 에 있어 구 URL 은 그냥 통과했다.
  # 판단과 실측은 .claude/rules/notes/xlsx-export.md
  describe "Excel 링크는 Turbo 의 방문 대상이 아니다" do
    # 레코드는 바깥 before 가 이미 만든다
    before { sign_in(admin) }

    screens = [
      { label: "관 상세",   page: -> { zone_path(zone) },                              link: -> { export_zone_animals_path(zone) } },
      { label: "건강 기록", page: -> { zone_animal_health_logs_path(zone, animal) },   link: -> { export_zone_animal_health_logs_path(zone, animal) } },
      { label: "먹이 기록", page: -> { zone_animal_feeding_logs_path(zone, animal) },  link: -> { export_zone_animal_feeding_logs_path(zone, animal) } },
      { label: "매출 기록", page: -> { sales_path },                                   link: -> { export_sales_path } },
      { label: "지출 기록", page: -> { expenses_path },                                link: -> { export_expenses_path } }
    ]

    screens.each do |screen|
      it "#{screen[:label]} — data-turbo=false 가 붙어 있다" do
        get instance_exec(&screen[:page])

        # 정규식으로 보면 속성 순서와 &amp; 이스케이프에 걸린다. 쿼리는 붙을 수
        # 있으므로 경로 앞부분으로 찾는다
        link = Nokogiri::HTML5(response.body).css("a[href^='#{instance_exec(&screen[:link])}']")

        expect(link.size).to eq(1)
        expect(link.first["data-turbo"]).to eq("false")
      end
    end
  end

  # 결정 ① — 구 URL 을 리다이렉트로 살리지 않는다. 링크는 ⋯ 메뉴에서 매번
  # 새로 생성되고, URL 을 살려도 require_login 이 있어 보안상 얻는 것이 없다
  describe "구 .xlsx URL 은 살리지 않는다" do
    before { sign_in(admin) }

    # 406 은 UnknownFormat 이 rescue 된 결과다. 예외로 단언하면 안 된다 —
    # 테스트 환경도 운영처럼 예외를 응답으로 렌더한다
    it "목록 경로의 xlsx 요청은 406 이 된다" do
      get sales_path(format: :xlsx)

      expect(response).to have_http_status(:not_acceptable)
    end

    # animals 는 index 자체를 없앴다. POST create 가 같은 경로를 쓰므로
    # zone_animals_path 헬퍼는 남는다
    it "동물 목록 경로의 GET 은 404 가 된다" do
      get zone_animals_path(zone)

      expect(response).to have_http_status(:not_found)
    end
  end
end
