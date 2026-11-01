# NoticesController — 인증·권한 제어
# Staff·Admin 모두 작성 가능, 수정·삭제는 본인 기록만 (Admin 은 타인 기록도 조작 가능)
require "rails_helper"

RSpec.describe "Notices", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }
  let(:other) { create(:user) }

  describe "GET /notices" do
    context "비로그인" do
      before { get notices_path }
      it_behaves_like "로그인이 필요하다"
    end

    context "로그인 상태" do
      before { sign_in(staff); get notices_path }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "GET /notices/:id" do
    let(:notice) { create(:notice, created_by: other, title: "히터 점검", content: "<div>본문 전문</div>") }

    context "비로그인" do
      before { get notice_path(notice) }
      it_behaves_like "로그인이 필요하다"
    end

    context "타인 공지도 읽을 수 있다" do
      before { sign_in(staff); get notice_path(notice) }

      it { expect(response).to have_http_status(:ok) }

      it "본문 전문을 낸다" do
        expect(response.body).to include("본문 전문")
      end
    end
  end

  describe "GET /notices (카테고리 필터)" do
    before do
      create(:notice, created_by: staff, category: :parrot,  title: "앵무새관 공지")
      create(:notice, created_by: staff, category: :reptile, title: "파충류관 공지")
      sign_in(staff)
    end

    it "category 를 넘기면 그 카테고리만 낸다" do
      get notices_path(category: "parrot")
      expect(response.body).to include("앵무새관 공지")
      expect(response.body).not_to include("파충류관 공지")
    end

    it "category 가 없으면 전건을 낸다" do
      get notices_path
      expect(response.body).to include("앵무새관 공지")
      expect(response.body).to include("파충류관 공지")
    end

    # enum 에 없는 값을 넘기면 ArgumentError 로 떨어진다.
    # URL 은 손으로 고칠 수 있으므로 모르는 값은 전건으로 다룬다
    it "모르는 category 는 전건으로 다룬다" do
      get notices_path(category: "nonsense")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("앵무새관 공지")
    end
  end

  describe "GET /notices (N+1)" do
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

    def notice_with_photo
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: "a.jpg", content_type: "image/jpeg"
      )
      create(:notice, created_by: staff, content: ActionText::Content.new.append_attachables(blob))
    end

    it "공지가 늘어도 쿼리 수가 늘지 않는다" do
      sign_in(staff)
      notice_with_photo
      few = query_count { get notices_path }

      3.times { notice_with_photo }
      many = query_count { get notices_path }

      expect(many).to eq(few)
    end
  end

  describe "GET /notices/new" do
    context "비로그인" do
      before { get new_notice_path }
      it_behaves_like "로그인이 필요하다"
    end

    context "로그인 상태" do
      before { sign_in(staff); get new_notice_path }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "POST /notices" do
    let(:valid_params) { { notice: { category: "general", title: "테스트 제목", content: "<div>테스트 공지</div>" } } }

    context "비로그인" do
      before { post notices_path, params: valid_params }
      it_behaves_like "로그인이 필요하다"
    end

    context "Staff 가 작성" do
      before { sign_in(staff) }

      it "created_by 가 자기 ID 로 저장되고 목록으로 보낸다" do
        post notices_path, params: valid_params
        expect(response).to redirect_to(notices_path)
        expect(Notice.last.created_by).to eq(staff)
      end

      it "본문이 리치텍스트로 저장된다" do
        post notices_path, params: valid_params
        expect(Notice.last.content.to_s).to include("테스트 공지")
      end
    end
  end

  describe "GET /notices/:id/edit" do
    context "본인 공지" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(staff); get edit_notice_path(notice) }
      it { expect(response).to have_http_status(:ok) }
    end

    context "타인 공지" do
      let(:notice) { create(:notice, created_by: other) }
      before { sign_in(staff); get edit_notice_path(notice) }
      it_behaves_like "접근이 거부된다"
    end

    context "Admin 이 타인 공지에 접근" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(admin); get edit_notice_path(notice) }
      it { expect(response).to have_http_status(:ok) }
    end
  end

  describe "PATCH /notices/:id" do
    let(:valid_params) { { notice: { title: "수정된 제목", content: "<div>수정된 공지</div>" } } }

    context "본인이 수정" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(staff) }

      it "공지를 수정하고 목록으로 보낸다" do
        patch notice_path(notice), params: valid_params
        expect(response).to redirect_to(notices_path)
        expect(notice.reload.content.to_s).to include("수정된 공지")
      end

      it "제목만 바꿔도 반영된다" do
        patch notice_path(notice), params: { notice: { title: "바뀐 제목" } }
        expect(notice.reload.title).to eq("바뀐 제목")
      end
    end

    context "타인 공지 수정을 시도" do
      let(:notice) { create(:notice, created_by: other) }
      before { sign_in(staff); patch notice_path(notice), params: valid_params }
      it_behaves_like "접근이 거부된다"
    end
  end

  describe "DELETE /notices/:id" do
    context "본인이 삭제" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(staff) }

      it "공지를 삭제하고 목록으로 보낸다" do
        delete notice_path(notice)
        expect(response).to redirect_to(notices_path)
        expect { notice.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "타인 공지 삭제를 시도" do
      let(:notice) { create(:notice, created_by: other) }
      before { sign_in(staff); delete notice_path(notice) }
      it_behaves_like "접근이 거부된다"
    end

    context "Admin 이 타인 공지를 삭제" do
      let(:notice) { create(:notice, created_by: staff) }
      before { sign_in(admin) }

      it "공지를 삭제하고 목록으로 보낸다" do
        delete notice_path(notice)
        expect(response).to redirect_to(notices_path)
        expect { notice.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
