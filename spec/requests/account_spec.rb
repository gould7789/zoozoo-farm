# AccountControllerのリクエストテスト — 認証制御とプロフィール表示を検証する
require "rails_helper"

RSpec.describe "Account", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:staff) { create(:user) }

  describe "GET /account" do
    # 未ログインはログインページへ強制リダイレクト
    context "未ログイン" do
      it "ログインページにリダイレクトする" do
        get account_path
        expect(response).to redirect_to(login_path)
      end
    end

    # Staffはマイページを閲覧可能
    context "Staffがアクセス" do
      before { sign_in(staff) }

      it "200を返す" do
        get account_path
        expect(response).to have_http_status(:ok)
      end
    end

    # Adminもマイページを閲覧可能
    context "Adminがアクセス" do
      before { sign_in(admin) }

      it "200を返す" do
        get account_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
