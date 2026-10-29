# ダイレクトアップロードの入口は Active Storage のエンジンが持つコントローラーで、
# このアプリの ApplicationController を継承しない。
# つまり before_action :require_login が効かず、素のままでは誰でも
# 署名付きアップロードURLを受け取れてしまう。
require "rails_helper"

RSpec.describe "Direct uploads", type: :request do
  let(:staff) { create(:user) }

  let(:blob_params) do
    { blob: { filename: "photo.jpg", byte_size: 10, checksum: "0" * 22, content_type: "image/jpeg" } }
  end

  context "未ログイン" do
    before { post rails_direct_uploads_path, params: blob_params }

    it "ログインページにリダイレクトする" do
      expect(response).to redirect_to(login_path)
    end

    it "blobを作らない" do
      expect(ActiveStorage::Blob.count).to eq(0)
    end
  end

  context "退職者（active = false）" do
    before do
      sign_in(staff)
      staff.update!(active: false)
      post rails_direct_uploads_path, params: blob_params
    end

    it "ログインページにリダイレクトする" do
      expect(response).to redirect_to(login_path)
    end
  end

  context "ログイン済み" do
    before { sign_in(staff); post rails_direct_uploads_path, params: blob_params }

    it "署名付きURLを返す" do
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("signed_id", "direct_upload")
    end
  end
end
