# Active Storage 의 입구는 엔진이 가진 컨트롤러라 이 앱의 ApplicationController 를
# 상속하지 않는다. 즉 before_action :require_login 이 듣지 않아, 손대지 않으면
# 누구나 서명된 업로드 URL 을 받을 수 있고 서명된 URL 을 알면 이미지도 열렸다.
#
# BaseController 에 인증을 붙였으므로 업로드와 열람 양쪽을 본다.
require "rails_helper"

RSpec.describe "Active Storage endpoints", type: :request do
  let(:staff) { create(:user) }

  let(:blob_params) do
    { blob: { filename: "photo.jpg", byte_size: 10, checksum: "0" * 22, content_type: "image/jpeg" } }
  end

  context "비로그인" do
    before { post rails_direct_uploads_path, params: blob_params }

    it "로그인 화면으로 보낸다" do
      expect(response).to redirect_to(login_path)
    end

    it "blob 을 만들지 않는다" do
      expect(ActiveStorage::Blob.count).to eq(0)
    end
  end

  context "退職者（active = false）" do
    before do
      sign_in(staff)
      staff.update!(active: false)
      post rails_direct_uploads_path, params: blob_params
    end

    it "로그인 화면으로 보낸다" do
      expect(response).to redirect_to(login_path)
    end
  end

  context "로그인 상태" do
    before { sign_in(staff); post rails_direct_uploads_path, params: blob_params }

    it "서명된 URL 을 반환한다" do
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("signed_id", "direct_upload")
    end
  end

  # 열람 쪽도 BaseController 아래다. 서명된 URL 은 추측할 수 없지만
  # 한 번 새면 기한 없이 계속 열린다. 작정한 내부자는 못 막지만 사고로 새는 경로는 닫는다
  describe "이미지 열람" do
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: "a.jpg", content_type: "image/jpeg"
      )
    end

    # 개별이 아니라 BaseController 에 붙였으므로 입구가 늘어도 덮인다.
    # 배열로 도는 이유는 「하나를 막는 걸 빠뜨렸다」를 떨구기 위해서다
    def paths
      {
        "原本（proxy）"    => rails_storage_proxy_path(blob),
        "原本（redirect）" => rails_blob_path(blob),
        "variant（proxy）" => rails_storage_proxy_path(blob.variant(resize_to_limit: [ 100, 100 ]))
      }
    end

    it "비로그인에서는 어느 경로도 열리지 않는다" do
      paths.each do |label, path|
        get path
        expect(response).to redirect_to(login_path), "#{label} 이 비로그인에서 열렸다"
      end
    end

    it "로그인 상태면 열린다" do
      sign_in(staff)
      paths.each do |label, path|
        get path
        expect(response).to have_http_status(:ok), "#{label} 이 로그인 상태에서 열리지 않는다"
      end
    end
  end
end
