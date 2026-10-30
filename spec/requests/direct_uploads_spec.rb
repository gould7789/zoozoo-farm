# Active Storage の入口は エンジンが持つコントローラーで、
# このアプリの ApplicationController を継承しない。
# つまり before_action :require_login が効かず、素のままでは誰でも
# 署名付きアップロードURLを受け取れ、署名付きURLを知っていれば画像も開けた。
#
# BaseController に認証を足しているので、アップロードと閲覧の両方を見る。
require "rails_helper"

RSpec.describe "Active Storage endpoints", type: :request do
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

  # 閲覧側も BaseController 配下にある。
  # 署名付きURLは推測できないが、一度漏れると期限なしで開き続ける。
  # 作り込んだ内部者は止められないが、事故で漏れた経路は閉じられる
  describe "画像の閲覧" do
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/animal.jpg").open,
        filename: "a.jpg", content_type: "image/jpeg"
      )
    end

    # 個別ではなく BaseController に付けているので、入口が増えても覆われる。
    # ここを配列で回すのは「どれか1つを塞ぎ忘れた」を落とすため
    def paths
      {
        "原本（proxy）"    => rails_storage_proxy_path(blob),
        "原本（redirect）" => rails_blob_path(blob),
        "variant（proxy）" => rails_storage_proxy_path(blob.variant(resize_to_limit: [ 100, 100 ]))
      }
    end

    it "未ログインではどの経路も開けない" do
      paths.each do |label, path|
        get path
        expect(response).to redirect_to(login_path), "#{label} が未ログインで開いた"
      end
    end

    it "ログイン済みなら開ける" do
      sign_in(staff)
      paths.each do |label, path|
        get path
        expect(response).to have_http_status(:ok), "#{label} がログイン済みで開かない"
      end
    end
  end
end
