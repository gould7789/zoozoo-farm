# ZonesControllerのリクエストテスト — 認証制御を中心に検証する
require "rails_helper"

RSpec.describe "Zones", type: :request do
  describe "GET /zones" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get zones_path
        expect(response).to redirect_to(login_path)
      end
    end

    # ログイン済みは正常表示
    context "ログイン済み" do
      before { sign_in(create(:user)) }

      it "200を返す" do
        get zones_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /zones/:id" do
    let(:zone) { create(:zone) }

    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get zone_path(zone)
        expect(response).to redirect_to(login_path)
      end
    end

    # ログイン済みは正常表示
    context "ログイン済み" do
      before { sign_in(create(:user)) }

      it "200を返す" do
        get zone_path(zone)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
